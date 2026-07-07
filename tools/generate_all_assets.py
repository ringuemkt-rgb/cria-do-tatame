#!/usr/bin/env python3
"""
CRIA DO TATAME - Asset Generator Pipeline
Usa Hugging Face Inference API (grátis) para gerar todos os assets
"""

import os
import requests
from pathlib import Path
from huggingface_hub import InferenceClient
from PIL import Image
import json

class AssetGenerator:
    def __init__(self):
        self.client = InferenceClient(token=os.getenv("HF_TOKEN", ""))
        self.output_dir = Path("assets")
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Modelos gratuitos do Hugging Face
        self.models = {
            "pixel_art": "nerijs/pixel-art-xl",
            "pixel_lora": "artificialguybr/PixelArtRedmond",
            "spritesheet": "Onodofthenorth/SD_PixelArt_SpriteSheet_Generator",
            "upscaler": "keras-io/BasicSR-RealESRGAN-x4plus"
        }
    
    def generate_pixel_art(self, prompt, output_path, negative_prompt="", width=1024, height=1024):
        """Gera pixel art usando modelos gratuitos"""
        full_prompt = f"""
        {prompt}, HD pixel art 2.5D, game sprite, professional quality,
        Baixo Sul da Bahia style, jiu-jitsu fighter, dark background,
        golden accents, consistent character design
        """
        
        if not negative_prompt:
            negative_prompt = """
            blurry, low quality, distorted proportions, modern clothing,
            weapons, cartoon style, deformed, extra limbs, watermark, text
            """
        
        try:
            image = self.client.text_to_image(
                prompt=full_prompt.strip(),
                model=self.models["pixel_art"],
                negative_prompt=negative_prompt,
                width=width,
                height=height,
                guidance_scale=7.5,
                num_inference_steps=30
            )
            
            # Downscale para pixel perfect (8x)
            image = image.resize((width // 8, height // 8), Image.Resampling.NEAREST)
            image.save(output_path, format="PNG")
            print(f"✅ Gerado: {output_path}")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao gerar {output_path}: {e}")
            return False
    
    def generate_character_sprites(self, character_data):
        """Gera todos os sprites de um personagem"""
        name = character_data["id"]
        display_name = character_data.get("display_name", character_data["name"])
        style = character_data.get("style", "jiu-jitsu fighter")
        
        poses = [
            ("idle", "standing relaxed pose"),
            ("walk", "walking cycle frame 1"),
            ("grip", "gripping opponent gi"),
            ("clinch", "close combat clinch position"),
            ("takedown", "executing takedown"),
            ("guard", "guard position defensive"),
            ("pass", "passing guard aggressive"),
            ("mount", "mount position dominant"),
            ("submission", "applying submission hold"),
            ("win", "victory pose triumphant"),
            ("lose", "defeat pose humbled")
        ]
        
        for pose_id, pose_desc in poses:
            prompt = f"""
            {display_name}, {style}, {pose_desc},
            white gi with Gorila Silverback patch,
            Brazilian jiu-jitsu athlete, compact muscular build,
            intense expression, professional game sprite
            """
            
            output_path = self.output_dir / "sprites" / f"{name}_{pose_id}.png"
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            self.generate_pixel_art(prompt, output_path)
    
    def generate_arena_backgrounds(self, arena_data):
        """Gera backgrounds de arenas em camadas"""
        arena_id = arena_data["id"]
        arena_name = arena_data["name"]
        arena_type = arena_data.get("type", "arena")
        
        layers = {
            "bg_far": "distant background scenery",
            "bg_mid": "midground elements and structures",
            "play_area": "fighting area tatame blue and gold",
            "foreground": "foreground details and crowd",
            "particles": "atmospheric particles and effects"
        }
        
        for layer_id, layer_desc in layers.items():
            prompt = f"""
            {arena_name} {arena_type}, {layer_desc},
            HD pixel art 2.5D background layer,
            Baixo Sul da Bahia atmosphere,
            professional game background
            """
            
            output_path = self.output_dir / "backgrounds" / arena_id / f"{layer_id}.png"
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            self.generate_pixel_art(prompt, output_path, width=1920, height=1080)
    
    def generate_ui_assets(self):
        """Gera elementos de UI"""
        ui_elements = {
            "button_normal": "game button normal state, dark panel gold border",
            "button_hover": "game button hover state, highlighted gold",
            "button_pressed": "game button pressed state, darker",
            "health_bar_full": "health bar full green to yellow gradient",
            "health_bar_empty": "health bar empty red segment",
            "stamina_bar": "stamina bar blue energy segments",
            "frame_border": "decorative frame border gold ornate",
            "icon_victory": "victory icon trophy gold",
            "icon_defeat": "defeat icon broken sword",
            "icon_pause": "pause icon two bars"
        }
        
        for element_id, element_desc in ui_elements.items():
            prompt = f"""
            {element_desc}, pixel art game UI element,
            dark background #1A1A1A, gold border #B8860B,
            clean readable design, mobile-friendly size
            """
            
            output_path = self.output_dir / "ui" / f"{element_id}.png"
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            self.generate_pixel_art(prompt, output_path, width=256, height=256)
    
    def generate_audio_prompts(self):
        """Gera prompts para áudio (serão processados por MusicGen)"""
        audio_prompts = {
            "terreiro_music": "Brazilian berimbau, subtle water sounds, wooden floor creaks, birds, deep ambient strings, calm and meditative, traditional jiu-jitsu atmosphere",
            "dique_music": "Heavy percussion, crowd cheering, gymnasium reverb, intense sports atmosphere, competitive energy",
            "lapa_music": "Metal sounds, rain, dark ambient, industrial tension, irregular rhythm, underground fight club",
            "sfx_grip": "Grip on gi fabric, cloth grabbing sound, jiu-jitsu uniform",
            "sfx_impact": "Body impact on mat, thud, jiu-jitsu takedown",
            "sfx_breathing": "Heavy breathing, exhaustion, martial arts training",
            "sfx_crowd": "Crowd cheering, sports arena, Brazilian crowd excited",
            "sfx_victory": "Victory announcement, crowd celebration, referee raising hand"
        }
        
        # Salvar prompts em JSON para processamento posterior
        output_path = self.output_dir / "audio" / "audio_prompts.json"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(audio_prompts, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Prompts de áudio salvos em: {output_path}")

def main():
    """Função principal de geração"""
    generator = AssetGenerator()
    
    # Carregar dados do repositório
    characters_path = Path("data/characters.json")
    arenas_path = Path("data/arenas.json")
    
    if characters_path.exists():
        with open(characters_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            characters = data.get("characters", [])
            
            # Filtrar apenas personagens canônicos
            canon_characters = [c for c in characters if c.get("canon", True)]
            
            print(f"\n🎨 Gerando sprites para {len(canon_characters)} personagens...")
            for character in canon_characters:
                print(f"\n→ {character.get('display_name', character['id'])}")
                generator.generate_character_sprites(character)
    
    if arenas_path.exists():
        with open(arenas_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            arenas = data.get("arenas", [])
            
            print(f"\n🏛️ Gerando backgrounds para {len(arenas)} arenas...")
            for arena in arenas:
                print(f"\n→ {arena.get('name', arena['id'])}")
                generator.generate_arena_backgrounds(arena)
    
    print("\n🎮 Gerando UI assets...")
    generator.generate_ui_assets()
    
    print("\n🎵 Gerando prompts de áudio...")
    generator.generate_audio_prompts()
    
    print("\n✅ Todos os assets gerados com sucesso!")

if __name__ == "__main__":
    main()
