#!/usr/bin/env python3
"""
Gera áudio e música usando MusicGen e Stable Audio (Hugging Face - grátis)
"""

import os
import json
from pathlib import Path
from huggingface_hub import InferenceClient

class AudioGenerator:
    def __init__(self):
        self.client = InferenceClient(token=os.getenv("HF_TOKEN", ""))
        self.output_dir = Path("assets/audio")
    
    def generate_music(self, prompt, output_path, duration=30):
        """Gera música usando MusicGen"""
        try:
            audio = self.client.text_to_audio(
                prompt=prompt,
                model="facebook/musicgen-small",
                duration=duration
            )
            
            # Salvar como OGG (formato Godot)
            output_path = Path(output_path).with_suffix(".ogg")
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_path, "wb") as f:
                f.write(audio)
            
            print(f"✅ Música gerada: {output_path}")
            return True
            
        except Exception as e:
            print(f"❌ Erro: {e}")
            return False
    
    def generate_sfx(self, prompt, output_path):
        """Gera SFX usando Stable Audio Open"""
        try:
            audio = self.client.text_to_audio(
                prompt=prompt,
                model="stabilityai/stable-audio-open-1.0",
                duration=5  # SFX curtos
            )
            
            output_path = Path(output_path).with_suffix(".wav")
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_path, "wb") as f:
                f.write(audio)
            
            print(f"✅ SFX gerado: {output_path}")
            return True
            
        except Exception as e:
            print(f"❌ Erro: {e}")
            return False
    
    def generate_all_audio(self):
        """Gera todos os áudios do jogo"""
        # Carregar prompts
        prompts_path = Path("assets/audio/audio_prompts.json")
        if not prompts_path.exists():
            print("❌ Prompts de áudio não encontrados. Execute generate_all_assets.py primeiro.")
            return
        
        with open(prompts_path, "r", encoding="utf-8") as f:
            prompts = json.load(f)
        
        print("\n🎵 Gerando trilhas sonoras...")
        music_prompts = {k: v for k, v in prompts.items() if "music" in k}
        for track_id, prompt in music_prompts.items():
            output_path = Path("assets/audio/music") / f"{track_id}.ogg"
            self.generate_music(prompt, output_path, duration=30)
        
        print("\n🔊 Gerando efeitos sonoros...")
        sfx_prompts = {k: v for k, v in prompts.items() if "sfx" in k}
        for sfx_id, prompt in sfx_prompts.items():
            output_path = Path("assets/audio/sfx") / f"{sfx_id}.wav"
            self.generate_sfx(prompt, output_path)

if __name__ == "__main__":
    generator = AudioGenerator()
    generator.generate_all_audio()
