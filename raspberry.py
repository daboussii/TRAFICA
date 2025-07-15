import io
import logging
import socketserver
from threading import Condition, Thread
from http import server
import time
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db

from picamera2 import Picamera2
import cv2
import numpy as np
from ultralytics import YOLO
from concurrent.futures import ThreadPoolExecutor
import queue
import uuid

# Page HTML de visualisation
PAGE = """\
<html>
<head>
<title>Camera Live Stream</title>
</head>
<body>
<center><h1>Camera Live Stream</h1></center>
<center><img src="stream.mjpg" width="640" height="480"></center>
</body>
</html>
"""

# Initialisation du modèle YOLO
model = YOLO('/home/mariem/Downloads/best.pt')
executor = ThreadPoolExecutor(max_workers=2)

# Configuration Firebase
cred = credentials.Certificate("/home/mariem/Downloads/smart-traffic-28a15-firebase-adminsdk-fbsvc-da849fdf0b.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://smart-traffic-28a15-default-rtdb.firebaseio.com/'
})

# Classes cibles pour la détection
target_classes = {"vehicule": [1, 2, 5], "ambulance": [3], "works": [6], "accidents": [0]}

# File d'attente pour les mises à jour Firebase
firebase_queue = queue.Queue()

class StreamingOutput:
    def __init__(self):
        self.frame = None
        self.condition = Condition()
        self.frame_count = 0
        self.last_process_time = 0
        # Références Firebase pour interB/ et intersectionB/
        self.ref_interB_veh = db.reference('interB/veh')
        self.ref_interB_urg = db.reference('interB/urg')
        self.ref_vehicule = db.reference('intersectionB/vehicules')
        self.ref_vehiculeUrg = db.reference('intersectionB/vehiculeUrg')
        # Initialiser les valeurs manuelles depuis interB/ avec gestion des types
        interB_veh_data = self.ref_interB_veh.get()
        self.default_interB_veh = interB_veh_data if isinstance(interB_veh_data, dict) else {'top': interB_veh_data if interB_veh_data is not None else 0}
        interB_urg_data = self.ref_interB_urg.get()
        self.default_interB_urg = interB_urg_data if isinstance(interB_urg_data, dict) else {'top': interB_urg_data if interB_urg_data is not None else 0}
        # Initialiser les valeurs manuelles depuis intersectionB/
        self.default_vehicule = self.ref_vehicule.get() or {'bottomA': 0}
        self.default_vehiculeUrg = self.ref_vehiculeUrg.get() or {'bottomA': 0}
        # Configurer les écouteurs pour les mises à jour manuelles
        self.ref_interB_veh.listen(self.update_interB_veh)
        self.ref_interB_urg.listen(self.update_interB_urg)
        self.ref_vehicule.listen(self.update_vehicule)
        self.ref_vehiculeUrg.listen(self.update_vehiculeUrg)
        self.vehicle_counts = {
            'vehicule': [0, 0, 0, 0],  # Top, Bottom, Left, Right pour l'intersection A
            'ambulance': [0, 0, 0, 0],
            'works': 0,
            'accidents': 0,
            'intersectionB_bottomA_vehicule': 0,  # Compteur détecté pour bottomA (véhicules)
            'intersectionB_bottomA_vehiculeUrg': 0  # Compteur détecté pour bottomA (véhicules urgents)
        }

    def update_interB_veh(self, event):
        if event.data:
            self.default_interB_veh = event.data if isinstance(event.data, dict) else {'top': event.data if event.data is not None else 0}
            logging.info(f"Mise à jour manuelle de interB/veh : {self.default_interB_veh}")

    def update_interB_urg(self, event):
        if event.data:
            self.default_interB_urg = event.data if isinstance(event.data, dict) else {'top': event.data if event.data is not None else 0}
            logging.info(f"Mise à jour manuelle de interB/urg : {self.default_interB_urg}")

    def update_vehicule(self, event):
        if event.data:
            self.default_vehicule = event.data
            logging.info(f"Mise à jour manuelle de intersectionB/vehicules : {self.default_vehicule}")

    def update_vehiculeUrg(self, event):
        if event.data:
            self.default_vehiculeUrg = event.data
            logging.info(f"Mise à jour manuelle de intersectionB/vehiculeUrg : {self.default_vehiculeUrg}")

    def write(self, buf):
        current_time = time.time()
        if current_time - self.last_process_time < 0.066:  # Cible 15 FPS
            return

        self.frame_count += 1
        self.last_process_time = current_time

        nparr = np.frombuffer(buf, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if frame is not None:
            frame_resized = cv2.resize(frame, (640, 480))
            future = executor.submit(self.process_frame, frame_resized)
            result = future.result()

            if result:
                with self.condition:
                    self.frame = result
                    self.condition.notify_all()

    def process_frame(self, frame):
        height, width = frame.shape[:2]

        # Définir les zones
        zones = {
            'Top': (int(width * 0.40), 0, int(width * 0.55), int(height * 0.30)),
            'Bottom': (int(width * 0.55), int(height * 0.65), int(width * 0.70), height),
            'Left': (0, int(height * 0.48), int(width * 0.45), int(height * 0.68)),
            'Right': (int(width * 0.65), int(height * 0.3), width, int(height * 0.49)),
            'BottomA': (int(width * 0.40), int(height * 0.65), int(width * 0.55), height)
        }

        # Réinitialiser les compteurs
        self.vehicle_counts = {
            'vehicule': [0, 0, 0, 0],
            'ambulance': [0, 0, 0, 0],
            'works': 0,
            'accidents': 0,
            'intersectionB_bottomA_vehicule': 0,
            'intersectionB_bottomA_vehiculeUrg': 0
        }

        # Appliquer YOLO
        results = model(frame, imgsz=640, conf=0.25, iou=0.4, verbose=False)

        # Copie de l'image originale pour dessin
        annotated_frame = frame.copy()

        for result in results[0].boxes:
            cls = int(result.cls[0])
            vehicle_type = None
            if cls in target_classes['vehicule']:
                vehicle_type = 'vehicule'
            elif cls in target_classes['ambulance']:
                vehicle_type = 'ambulance'
            elif cls in target_classes['works']:
                vehicle_type = 'works'
            elif cls in target_classes['accidents']:
                vehicle_type = 'accidents'

            if vehicle_type:
                if vehicle_type in ['vehicule', 'ambulance']:
                    self.count_vehicle_in_zones(result.xyxy[0], vehicle_type, zones)
                    if self.is_in_zone(result.xyxy[0], zones['BottomA']):
                        if vehicle_type == 'vehicule':
                            self.vehicle_counts['intersectionB_bottomA_vehicule'] += 1
                        elif vehicle_type == 'ambulance':
                            self.vehicle_counts['intersectionB_bottomA_vehiculeUrg'] += 1
                elif vehicle_type in ['works', 'accidents']:
                    self.vehicle_counts[vehicle_type] += 1

        # Mettre les comptes dans la file d'attente Firebase
        firebase_queue.put(self.vehicle_counts.copy())

        # Dessiner les boîtes de détection
        annotated_frame = results[0].plot(labels=True, conf=True, font_size=6)

        # Dessiner les zones sur l'image
        colors = {
            'Top': (255, 0, 0),
            'Bottom': (0, 255, 0),
            'Left': (0, 0, 255),
            'Right': (255, 255, 0),
            'BottomA': (0, 255, 255)
        }

        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 0.2
        thickness = 1

        for zone_name, (x1, y1, x2, y2) in zones.items():
            x1, y1, x2, y2 = map(int, (x1, y1, x2, y2))
            cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), colors[zone_name], 1)
            cv2.putText(annotated_frame, zone_name, (x1 + 5, y1 + 15),
                        font, font_scale, colors[zone_name], thickness)

        # Annotations de comptage
        font_scale_counts = 0.3
        line1 = f"Vehicules - T: {self.vehicle_counts['vehicule'][0]} B: {self.vehicle_counts['vehicule'][1]} L: {self.vehicle_counts['vehicule'][2]} R: {self.vehicle_counts['vehicule'][3]}"
        line2 = f"Ambulances - T: {self.vehicle_counts['ambulance'][0]} B: {self.vehicle_counts['ambulance'][1]} L: {self.vehicle_counts['ambulance'][2]} R: {self.vehicle_counts['ambulance'][3]}"
        line3 = f"Works - Total: {self.vehicle_counts['works']}"
        line4 = f"Accidents - Total: {self.vehicle_counts['accidents']}"
        line5 = f"IntersectionB - Vehicules T: {(self.default_interB_veh.get('top', 0) if self.default_interB_veh else 0) + self.vehicle_counts['intersectionB_bottomA_vehicule']} (BottomA: {self.vehicle_counts['intersectionB_bottomA_vehicule']})"
        line6 = f"IntersectionB - VehiculeUrg T: {(self.default_interB_urg.get('top', 0) if self.default_interB_urg else 0) + self.vehicle_counts['intersectionB_bottomA_vehiculeUrg']} (BottomA: {self.vehicle_counts['intersectionB_bottomA_vehiculeUrg']})"

        cv2.putText(annotated_frame, line1, (5, height - 70), font, font_scale_counts, (0, 255, 255), thickness)
        cv2.putText(annotated_frame, line2, (5, height - 60), font, font_scale_counts, (0, 255, 255), thickness)
        cv2.putText(annotated_frame, line3, (5, height - 50), font, font_scale_counts, (0, 255, 255), thickness)
        cv2.putText(annotated_frame, line4, (5, height - 40), font, font_scale_counts, (0, 255, 255), thickness)
        cv2.putText(annotated_frame, line5, (5, height - 25), font, font_scale_counts, (0, 255, 255), thickness)
        cv2.putText(annotated_frame, line6, (5, height - 10), font, font_scale_counts, (0, 255, 255), thickness)

        ret, jpeg = cv2.imencode('.jpg', annotated_frame, [int(cv2.IMWRITE_JPEG_QUALITY), 95])
        return jpeg.tobytes() if ret else None

    def count_vehicle_in_zones(self, bbox, vehicle_type, zones):
        x1, y1, x2, y2 = bbox
        cx = (x1 + x2) / 2
        cy = (y1 + y2) / 2

        for idx, (zone_name, (zx1, zy1, zx2, zy2)) in enumerate(zones.items()):
            if zone_name != 'BottomA' and zx1 <= cx <= zx2 and zy1 <= cy <= zy2:
                self.vehicle_counts[vehicle_type][idx] += 1

    def is_in_zone(self, bbox, zone):
        x1, y1, x2, y2 = bbox
        cx = (x1 + x2) / 2
        cy = (y1 + y2) / 2
        zx1, zy1, zx2, zy2 = zone
        return zx1 <= cx <= zx2 and zy1 <= cy <= zy2

    def send_counts_to_firebase(self):
        while True:
            try:
                vehicle_counts = firebase_queue.get(block=True)
                # Lire les valeurs actuelles depuis interB/ et intersectionB/
                current_interB_veh = self.ref_interB_veh.get()
                current_interB_urg = self.ref_interB_urg.get()
                current_vehicule = self.ref_vehicule.get() or {'bottomA': 0}
                current_vehiculeUrg = self.ref_vehiculeUrg.get() or {'bottomA': 0}

                data = {
                    'vehicules': {
                        'top': vehicle_counts['vehicule'][0],
                        'bottom': vehicle_counts['vehicule'][1],
                        'left': vehicle_counts['vehicule'][2],
                        'right': vehicle_counts['vehicule'][3],
                        'total': sum(vehicle_counts['vehicule']),
                    },
                    'ambulances': {
                        'top': vehicle_counts['ambulance'][0],
                        'bottom': vehicle_counts['ambulance'][1],
                        'left': vehicle_counts['ambulance'][2],
                        'right': vehicle_counts['ambulance'][3],
                        'total': sum(vehicle_counts['ambulance']),
                    },
                    'works': {
                        'total': vehicle_counts['works'] > 0
                    },
                    'accidents': {
                        'total': vehicle_counts['accidents'] > 0
                    },
                    'intersectionB': {
                        'vehiculeUrg': {
                            'top': (current_interB_urg.get('top', 0) if current_interB_urg else 0) + vehicle_counts['intersectionB_bottomA_vehiculeUrg'],
                            'bottomA': vehicle_counts['intersectionB_bottomA_vehiculeUrg']
                        },
                        'vehicules': {
                            'top': (current_interB_veh.get('top', 0) if current_interB_veh else 0) + vehicle_counts['intersectionB_bottomA_vehicule'],
                            'bottomA': vehicle_counts['intersectionB_bottomA_vehicule']
                        }
                    }
                }
                ref = db.reference('comptage')
                ref.set(data)
                firebase_queue.task_done()
            except Exception as e:
                logging.error(f"Erreur Firebase : {str(e)}")
                time.sleep(1)

class StreamingHandler(server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(301)
            self.send_header('Location', '/index.html')
            self.end_headers()
        elif self.path == '/index.html':
            content = PAGE.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.send_header('Content-Length', len(content))
            self.end_headers()
            self.wfile.write(content)
        elif self.path == '/stream.mjpg':
            self.send_response(200)
            self.send_header('Age', 0)
            self.send_header('Cache-Control', 'no-cache, private')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Content-Type', 'multipart/x-mixed-replace; boundary=FRAME')
            self.end_headers()
            try:
                while True:
                    with output.condition:
                        output.condition.wait()
                        frame = output.frame
                    self.wfile.write(b'--FRAME\r\n')
                    self.send_header('Content-Type', 'image/jpeg')
                    self.send_header('Content-Length', len(frame))
                    self.end_headers()
                    self.wfile.write(frame)
                    self.wfile.write(b'\r\n')
            except Exception as e:
                logging.warning('Suppression du flux client : %s', str(e))
        else:
            self.send_error(404)
            self.end_headers()

class StreamingServer(socketserver.ThreadingMixIn, server.HTTPServer):
    allow_reuse_address = True
    daemon_threads = True

def camera_loop():
    picam2 = Picamera2()
    picam2.configure(picam2.create_video_configuration(main={"format": 'RGB888', "size": (640, 480)}))
    picam2.start()

    while True:
        frame = picam2.capture_array()
        ret, jpeg = cv2.imencode('.jpg', frame, [int(cv2.IMWRITE_JPEG_QUALITY), 95])
        if ret:
            output.write(jpeg.tobytes())
        time.sleep(0.033)

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    output = StreamingOutput()
    address = ('', 8000)
    server = StreamingServer(address, StreamingHandler)

    # Démarrer le thread Firebase
    firebase_thread = Thread(target=output.send_counts_to_firebase, daemon=True)
    firebase_thread.start()

    print("Serveur démarré sur http://localhost:8000")

    thread = Thread(target=camera_loop)
    thread.start()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nArrêt du serveur")




