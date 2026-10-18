#!/usr/bin/env python3
"""Build an offline Portuguese review gallery using the actual encoded GIFs."""
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / 'production/grappling_gifs_v1'


def render():
    manifest = json.loads((PACKAGE / 'manifest.json').read_text())
    cards = []
    for clip in manifest['clips']:
        group = ('bracos' if clip['family'] in ['arm_lock', 'shoulder_lock'] else
                 'pernas' if 'leg_lock' in clip['family'] else
                 'fluxo' if clip['family'] == 'combat_flow' else 'guardas')
        title = html.escape(clip['name'])
        gif = '../../' + clip['gif']
        sheet = '../../' + clip['source_image']
        issues = ''.join('<li>' + html.escape(x) + '</li>' for x in clip['visual_observations'])
        cards.append(f'''<article data-group="{group}" data-name="{title.lower()}">
<div class="cardhead"><h2>{title}</h2><span class="badge">Redesenhar</span></div>
<img src="{gif}" alt="Animático de seis poses planejadas para {title}; revisão técnica pendente" loading="lazy" width="384" height="384">
<p class="meta">NO-GI · 6 poses · 5,5 s · prévia em loop</p>
<details><summary>O que precisa de revisão</summary><ul>{issues}</ul></details>
<div class="links"><a href="{gif}" download>Baixar GIF</a><a href="{sheet}">Ver prancha</a></div>
</article>''')
    template = '''<!doctype html>
<html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cria do Tatame — Animáticos NO-GI</title>
<style>
:root{color-scheme:dark;--gold:#e0b45b;--muted:#b7bdb5}*{box-sizing:border-box}body{margin:0;background:#101713;color:#f0eee7;font:16px/1.55 system-ui,sans-serif}main{max-width:1150px;margin:auto;padding:28px 20px 64px}header{padding:24px 0 32px;border-bottom:1px solid #394536}.eyebrow{letter-spacing:.18em;color:var(--gold);font-size:12px;font-weight:700}h1{font-size:clamp(32px,6vw,60px);line-height:1.06;max-width:750px;margin:18px 0}p{max-width:850px}.lede{color:var(--muted)}.stats{display:flex;gap:32px;flex-wrap:wrap;margin-top:28px}.stats b{font-size:30px;display:block;color:var(--gold)}.stats span{color:var(--muted);font-size:13px}.notice{background:#25271c;border-left:3px solid var(--gold);padding:16px 20px;margin:28px 0}.flow{display:flex;flex-wrap:wrap;gap:12px;list-style-position:inside;padding:0}.flow li{padding:9px 13px;border:1px solid #4b5949;border-radius:6px}.filter{display:flex;gap:12px;flex-wrap:wrap;margin:30px 0 18px}input,select{padding:12px;background:#1a241d;border:1px solid #53634f;color:#fff;border-radius:6px;font:inherit}input{flex:1;min-width:200px}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:22px}article{background:#19221b;border:1px solid #3b4a37;padding:18px;border-radius:12px;overflow:hidden}.cardhead{display:flex;gap:12px;align-items:start;justify-content:space-between}h2{font-size:20px;line-height:1.3;margin:0 0 18px}.badge{font-size:11px;padding:4px 8px;white-space:nowrap;background:#4b361b;color:#ffe0a0;border-radius:4px}img{display:block;width:100%;height:auto;max-width:384px;aspect-ratio:1;margin:auto;border-radius:6px}.meta{font-size:13px;color:var(--muted)}summary{cursor:pointer;color:var(--gold)}li{margin:6px 0}.links{display:flex;gap:22px;margin-top:20px}a{color:var(--gold);text-underline-offset:4px}footer{margin-top:36px;color:var(--muted);font-size:13px}article[hidden]{display:none}@media(max-width:720px){.grid{grid-template-columns:1fr}.cardhead{display:block}.badge{display:inline-block;margin-bottom:12px}}
</style><main><header><div class="eyebrow">CRIA DO TATAME / ESTÚDIO DE MOVIMENTO</div><h1>Jiu-jitsu em movimento.</h1><p class="lede">Lote de revisão com Ruan e Davi: braços, pernas, guardas e fluxo de combate. Cada animação alterna seis poses desenhadas; ainda não é uma animação fluida de produção.</p><div class="stats"><div><b>13</b><span>GIFs de revisão</span></div><div><b>78</b><span>poses candidatas</span></div><div><b>0</b><span>técnicas aprovadas para o jogo</span></div></div></header>
<aside class="notice"><strong>Redesenho e revisão técnica pendentes.</strong> Há encaixes ambíguos, variações de identidade e contatos que precisam ser corrigidos. Os rascunhos não servem como demonstração biomecânica aprovada. A reprodução em loop apenas reinicia a apresentação.</aside>
<h2>Fluxo planejado</h2><ol class="flow"><li>Em pé</li><li>Queda / meia-guarda</li><li>Passagem / lateral</li><li>Montada</li><li>Chave de braço / soltura</li></ol><p class="lede">Alternativas existentes: sprawl e recuperação de meia-guarda. De La Riva, Reverse De La Riva e berimbolo são propostas ainda sem transição cadastrada. Pontos e resultado continuam sob as regras do jogo.</p>
<div class="filter"><input id="search" type="search" placeholder="Buscar técnica" aria-label="Buscar técnica"><select id="family" aria-label="Filtrar família"><option value="all">Todas as famílias</option><option value="bracos">Braços e ombros</option><option value="pernas">Chaves de perna</option><option value="guardas">Guardas e berimbolo</option><option value="fluxo">Fluxo de combate</option></select></div><p id="count" class="meta">13 prévias</p><section class="grid">__CARDS__</section>
<footer>ADCC: consultar evento, edição, idade e nível antes de liberar ataques. Matriz Opens ainda não implementada. Referências: <a href="https://adcombat.com/adcc-rules-regulations/">Championship</a> e <a href="https://adcc-official.com/pages/adcc-rules">Opens</a>. Nenhuma regra de combate foi alterada por este pacote.</footer></main><script>
const search=document.querySelector('#search'),family=document.querySelector('#family');
function filter(){let count=0;for(const card of document.querySelectorAll('article')){const show=(family.value==='all'||card.dataset.group===family.value)&&card.dataset.name.includes(search.value.toLocaleLowerCase('pt-BR'));card.hidden=!show;if(show)count++;}document.querySelector('#count').textContent=count+' prévias';}search.addEventListener('input',filter);family.addEventListener('change',filter);
</script></html>'''
    (PACKAGE / 'index.html').write_text(template.replace('__CARDS__', '\n'.join(cards)), encoding='utf-8')
    print('Offline gallery rendered: 13 cards')


if __name__ == '__main__':
    render()
