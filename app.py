from flask import Flask, request, jsonify, send_file
import os

app = Flask(__name__)

@app.route('/upload_pdf', methods=['POST'])
def upload_pdf():
    pdf = request.files['file']
    pdf.save("uploaded.pdf")
    # TODO: Add your OCR + AI video generation logic here
    return jsonify({"message": "PDF uploaded successfully"})

@app.route('/generate_video', methods=['POST'])
def generate_video():
    # TODO: Call your model inference here
    video_path = "output_video.mp4"
    return send_file(video_path, as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) 