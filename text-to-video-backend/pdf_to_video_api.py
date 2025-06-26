from flask import Flask, request, send_file
import pdfplumber, os
from gtts import gTTS
from diffusers import StableDiffusionPipeline
from moviepy.editor import ImageClip, AudioFileClip, concatenate_videoclips
import torch
from PIL import Image
import uuid

app = Flask(__name__)

@app.route('/')
def home():
    return "🎉 PDF to Video Backend is Live on Render!"

@app.route('/upload', methods=['POST'])
def upload_pdf():
    file = request.files.get('file')
    if not file:
        return {"error": "No file uploaded"}, 400

    uid = str(uuid.uuid4())[:8]
    filename = f"input_{uid}.pdf"
    file.save(filename)

    # Extract text from PDF
    pdf_text = ""
    with pdfplumber.open(filename) as pdf:
        for page in pdf.pages:
            pdf_text += page.extract_text() + "\n"

    paragraphs = [p.strip() for p in pdf_text.split('\n') if p.strip()]

    # Generate audio clips
    audio_dir = f"audio_{uid}"
    os.makedirs(audio_dir, exist_ok=True)
    audio_files = []
    for i, para in enumerate(paragraphs):
        tts = gTTS(para)
        audio_path = f"{audio_dir}/audio_{i}.mp3"
        tts.save(audio_path)
        audio_files.append(audio_path)

    # Generate images
    image_dir = f"images_{uid}"
    os.makedirs(image_dir, exist_ok=True)
    pipe = StableDiffusionPipeline.from_pretrained(
        "runwayml/stable-diffusion-v1-5", torch_dtype=torch.float16
    ).to("cuda")

    image_files = []
    for i, para in enumerate(paragraphs):
        image = pipe(para).images[0]
        image_path = f"{image_dir}/image_{i}.png"
        image.save(image_path)
        image_files.append(image_path)

    # Combine into video
    clips = []
    for i in range(len(paragraphs)):
        img_clip = ImageClip(image_files[i]).set_duration(AudioFileClip(audio_files[i]).duration)
        img_clip = img_clip.set_audio(AudioFileClip(audio_files[i]))
        clips.append(img_clip)

    final_video = concatenate_videoclips(clips, method="compose")
    output_video = f"output_{uid}.mp4"
    final_video.write_videofile(output_video, fps=24)

    return send_file(output_video, as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
