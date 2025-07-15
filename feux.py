from machine import Pin
from time import sleep
import urequests
import network
import ujson

# ==== Connexion WiFi ====
ssid = "CRNS"
password = "Crns#2020#"

station = network.WLAN(network.STA_IF)
station.active(True)
station.connect(ssid, password)

while not station.isconnected():
    pass
print('WiFi connecté avec IP:', station.ifconfig())

# ==== Broches pour 4 feux ====
RED1_PIN = Pin(14, Pin.OUT)    # Left
ORANGE1_PIN = Pin(13, Pin.OUT) # Left
GREEN1_PIN = Pin(17, Pin.OUT)

RED2_PIN = Pin(23, Pin.OUT)    # Right
ORANGE2_PIN = Pin(22, Pin.OUT)
GREEN2_PIN = Pin(21, Pin.OUT)

RED3_PIN = Pin(19, Pin.OUT)    # Top
ORANGE3_PIN = Pin(18, Pin.OUT)
GREEN3_PIN = Pin(5, Pin.OUT)

RED4_PIN = Pin(15, Pin.OUT)    # Bottom
ORANGE4_PIN = Pin(2, Pin.OUT)
GREEN4_PIN = Pin(4, Pin.OUT)

# Réinitialisation de toutes les broches au démarrage (tous les feux au rouge)
def reset_all_lights(controller):
    print("Réinitialisation de toutes les broches à rouge...")
    controller.set_light("left", "red")
    controller.set_light("right", "red")
    controller.set_light("top", "red")
    controller.set_light("bottom", "red")

# ==== Adresses Firebase ====
FIREBASE_COUNT_URL = "https://smart-traffic-28a15-default-rtdb.firebaseio.com/comptage.json"
FIREBASE_LIGHTS_URL = "https://smart-traffic-28a15-default-rtdb.firebaseio.com/feux.json"

# ==== Classe pour gérer les feux ====
class TrafficLightController:
    def __init__(self):
        self.lights = {"left": "red", "right": "red", "top": "red", "bottom": "red"}
        self.vehicle_count = {"left": 0, "right": 0, "top": 0, "bottom": 0}
        self.emergency_vehicle = {"left": False, "right": False, "top": False, "bottom": False}
        self.last_green = None
        self.consecutive_green_count = 0  # Compteur pour les cycles consécutifs
        self.default_cycle = ["left", "right", "top", "bottom"]
        self.cycle_index = 0

    def set_vehicle_count(self, left, right, top, bottom):
        self.vehicle_count["left"] = left
        self.vehicle_count["right"] = right
        self.vehicle_count["top"] = top
        self.vehicle_count["bottom"] = bottom

    def set_emergency_vehicle(self, left, right, top, bottom):
        self.emergency_vehicle["left"] = left > 0
        self.emergency_vehicle["right"] = right > 0
        self.emergency_vehicle["top"] = top > 0
        self.emergency_vehicle["bottom"] = bottom > 0

    def update_firebase_lights(self):
        """Met à jour l'état des feux sur Firebase"""
        try:
            data = {
                "left": self.lights["left"],
                "right": self.lights["right"],
                "top": self.lights["top"],
                "bottom": self.lights["bottom"]
            }
            response = urequests.patch(FIREBASE_LIGHTS_URL, data=ujson.dumps(data))
            response.close()
            print("État des feux mis à jour sur Firebase")
        except Exception as e:
            print(f"Erreur lors de la mise à jour des feux sur Firebase: {str(e)}")

    def set_light(self, lane, color):
        if lane in ["bottom", "left"]:
            print(f"Commande pour '{lane}': rouge={1 if color == 'red' else 0}, orange={1 if color == 'orange' else 0}, vert={1 if color == 'green' else 0}")
        if lane == "left":
            RED1_PIN.value(1 if color == "red" else 0)
            ORANGE1_PIN.value(1 if color == "orange" else 0)
            GREEN1_PIN.value(1 if color == "green" else 0)
        elif lane == "right":
            RED2_PIN.value(1 if color == "red" else 0)
            ORANGE2_PIN.value(1 if color == "orange" else 0)
            GREEN2_PIN.value(1 if color == "green" else 0)
        elif lane == "top":
            RED3_PIN.value(1 if color == "red" else 0)
            ORANGE3_PIN.value(1 if color == "orange" else 0)
            GREEN3_PIN.value(1 if color == "green" else 0)
        elif lane == "bottom":
            RED4_PIN.value(1 if color == "red" else 0)
            ORANGE4_PIN.value(1 if color == "orange" else 0)
            GREEN4_PIN.value(1 if color == "green" else 0)
       
        # Mettre à jour l'état interne et Firebase
        self.lights[lane] = color
        self.update_firebase_lights()
        print(f"Feu {lane} est {color}")

    def get_max_vehicle_lane(self):
        max_count = max(self.vehicle_count.values())
        max_lanes = [lane for lane, count in self.vehicle_count.items() if count == max_count]
        if len(max_lanes) > 1:
            return None
        return max_lanes[0] if max_lanes else None

    def get_emergency_lanes(self):
        return [lane for lane, has_emergency in self.emergency_vehicle.items() if has_emergency]

    def control_traffic(self):
        # Réinitialisation des feux à rouge (au lieu de tous éteints)
        reset_all_lights(self)
        sleep(0.2)  # Attendre 2 secondes avec tous les feux au rouge

        # Cas 1 : vehicules d'urgence
        emergency_lanes = self.get_emergency_lanes()
        if emergency_lanes:
            if len(emergency_lanes) == 1:
                lane = emergency_lanes[0]
                green_time = max(10, self.vehicle_count[lane]*5)
                print(f"Ambulance sur {lane}, feu vert pour {green_time}s")
                self.set_light(lane, "orange")  # Phase orange
                sleep(1)
                self.set_light(lane, "green")
                sleep(green_time)
                self.set_light(lane, "red")  # Retour au rouge
                if self.last_green == lane:
                    self.consecutive_green_count += 1
                else:
                    self.last_green = lane
                    self.consecutive_green_count = 1
                return
            else:
                max_lane = max(
                    emergency_lanes,
                    key=lambda lane: self.vehicle_count[lane],
                    default=emergency_lanes[0]
                )
                green_time = max(10, self.vehicle_count[max_lane])
                print(f"Ambulances multiples, priorité à {max_lane} pour {green_time}s")
                self.set_light(max_lane, "orange")  # Phase orange
                sleep(1)
                self.set_light(max_lane, "green")
                sleep(green_time)
                self.set_light(max_lane, "red")  # Retour au rouge
                if self.last_green == max_lane:
                    self.consecutive_green_count += 1
                else:
                    self.last_green = max_lane
                    self.consecutive_green_count = 1
                return

        # Cas 2 : Max véhicules
        max_lane = self.get_max_vehicle_lane()
        if max_lane and self.vehicle_count[max_lane] > 0:
            if self.last_green == max_lane and self.consecutive_green_count >= 2:
                print(f"{max_lane} a été vert deux fois consécutivement, recherche de la voie avec le plus de véhicules")
                other_lanes = [lane for lane in self.vehicle_count if lane != max_lane]
                if other_lanes:
                    next_lane = max(other_lanes, key=lambda lane: self.vehicle_count[lane])
                    if self.vehicle_count[next_lane] > 0:
                        green_time = min(self.vehicle_count[next_lane] * 2, 30)
                        print(f"Passage à {next_lane} avec {self.vehicle_count[next_lane]} véhicules, feu vert pour {green_time}s")
                        self.set_light(next_lane, "orange")  # Phase orange
                        sleep(1)
                        self.set_light(next_lane, "green")
                        sleep(green_time)
                        self.set_light(next_lane, "red")  # Retour au rouge
                        self.last_green = next_lane
                        self.consecutive_green_count = 1
                        return
                    else:
                        print(f"Aucune autre voie avec des véhicules, passage au cycle par défaut")
                else:
                    print(f"Aucune autre voie disponible, passage au cycle par défaut")
            else:
                green_time = min(self.vehicle_count[max_lane] * 2, 30)
                print(f"Plus de véhicules sur {max_lane}, feu vert pour {green_time}s")
                self.set_light(max_lane, "orange")  # Phase orange
                sleep(1)
                self.set_light(max_lane, "green")
                sleep(green_time)
                self.set_light(max_lane, "red")  # Retour au rouge
                if self.last_green == max_lane:
                    self.consecutive_green_count += 1
                else:
                    self.last_green = max_lane
                    self.consecutive_green_count = 1
                return

        # Cas 3 : Cycle par défaut
        lane = self.default_cycle[self.cycle_index]
        while lane == self.last_green and self.consecutive_green_count >= 2:
            print(f"{lane} ignorée pour éviter une troisième ouverture consécutive")
            self.cycle_index = (self.cycle_index + 1) % len(self.default_cycle)
            lane = self.default_cycle[self.cycle_index]
        green_time = 3
        print(f"Cycle par défaut sur {lane}, feu vert pour {green_time}s")
        self.set_light(lane, "orange")  # Phase orange
        sleep(1)
        self.set_light(lane, "green")
        sleep(green_time)
        self.set_light(lane, "red")  # Retour au rouge
        if self.last_green == lane:
            self.consecutive_green_count += 1
        else:
            self.last_green = lane
            self.consecutive_green_count = 1
        self.cycle_index = (self.cycle_index + 1) % len(self.default_cycle)

# ==== Boucle principale ====
controller = TrafficLightController()

error_count = 0
while True:
    try:
        print("Lecture Firebase...")
        response = urequests.get(FIREBASE_COUNT_URL)
        data = response.json()
        response.close()
        error_count = 0  # Réinitialiser le compteur en cas de succès

        vehicules = data.get('vehicules', {})
        ambulances = data.get('ambulances', {})

        left = vehicules.get('left', 0)
        right = vehicules.get('right', 0)
        top = vehicules.get('top', 0)
        bottom = vehicules.get('bottom', 0)

        ambulance_left = ambulances.get('left', 0)
        ambulance_right = ambulances.get('right', 0)
        ambulance_top = ambulances.get('top', 0)
        ambulance_bottom = ambulances.get('bottom', 0)

        print(f"Voitures - Left: {left}, Right: {right}, Top: {top}, Bottom: {bottom}")
        print(f"Ambulances - Left: {ambulance_left}, Right: {ambulance_right}, Top: {ambulance_top}, Bottom: {ambulance_bottom}")

        controller.set_vehicle_count(left, right, top, bottom)
        controller.set_emergency_vehicle(ambulance_left, ambulance_right, ambulance_top, ambulance_bottom)

        controller.control_traffic()

    except Exception as e:
        error_count += 1
        print(f"Erreur détaillée #{error_count}: {str(e)}")
        reset_all_lights(controller)  # Réinitialisation immédiate
        for _ in range(3):  # Réduit à 3 cycles
            for lane in controller.lights:
                controller.set_light(lane, "orange")
            sleep(0.5)  # Réduit à 0,5 seconde
            for lane in controller.lights:
                controller.set_light(lane, "red")
            sleep(0.5)
        reset_all_lights(controller)  # Réinitialisation après mode erreur
        sleep(2)