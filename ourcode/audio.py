from pydub import AudioSegment

input_file = "input.mp3"
output_file = "audio.bin"

audio = AudioSegment.from_file(input_file)

# mono, 16-bit, 32000Hz
audio = audio.set_channels(1)
audio = audio.set_sample_width(2)  # 16-bit = 2 bytes
audio = audio.set_frame_rate(32000)
pcm_data = audio.raw_data

with open(output_file, 'wb') as f:
    f.write(pcm_data)