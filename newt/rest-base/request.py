import requests
import base64

with open("panda_sq.ppm", "rb") as image_file:
    encoded_string = base64.b64encode(image_file.read())

r = requests.get('http://127.0.0.1:8888/predict/infer_json', 
    data = {"input1":5, "input2":"panda_sq.ppm", "input3":encoded_string})