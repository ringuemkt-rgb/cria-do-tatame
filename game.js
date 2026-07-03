// Cria do Tatame — Sprint 0 playable web build
// Deterministic browser game. AI content enters only as validated JSON.

const STORE = 'cria_do_tatame_sprint0_v1';
const DAYS = ['Segunda','Terça','Quarta','Quinta','Sexta','Sábado','Domingo'];
const POS = { standup:'Em pé', clinch:'Clinch', guard_top:'Guarda por cima', side_control:'Cem quilos', mount:'Montada', lock:'Controle final' };
const BELTS = ['Branca','Azul','Roxa','Marrom','Preta'];
const DATA = {
  characters:'./data/characters.json',
  techniques:'./data/techniques.json',
  missions:'./data/missions.json',
  arenas:'./data/arenas.json',
  live:'./data/cria_live_posts.json'
};

const fallback = {
  characters:{characters:[
    {id:'ruan_macacao',name:'Ruan Silva',nickname:'Macacão',stats:{hp:120,stamina:105,technique:55,pressure:90,focus:60,grip_strength:95,speed:45}},
    {id:'davi_relampago',name:'Davi Relâmpago',nickname:'Relâmpago',stats:{hp:92,stamina:120,technique:58,pressure:42,focus:65,grip_strength:42,speed:88}}
  ]},
  techniques:{techniques:[
    {id:'clinch',name:'Puxada para o Clinch',from:['standup'],to:'clinch',cost:12,focus:0,power:14,grip:16,base:8,control:0,belt:'Branca'},
    {id:'baiana',name:'Baiana de Pressão',from:['clinch','standup'],to:'guard_top',cost:20,focus:4,power:24,grip:12,base:26,control:0,belt:'Branca'},
    {id:'passagem',name:'Passagem Pesada',from:['guard_top'],to:'side_control',cost:24,focus:5,power:28,grip:10,base:18,control:0,belt:'Branca'},
    {id:'montada',name:'Montada Silverback',from:['side_control'],to:'mount',cost:18,focus:5,power:26,grip:18,base:12,control:15,belt:'Branca'},
    {id:'controle_final',name:'Controle Final',from:['mount','side_control'],to:'lock',cost:30,focus:10,power:34,grip:24,base:12,control:45,belt:'Azul'},
    {id:'respirar',name:'Respirar e Firmar Base',from:['standup','clinch','guard_top','side_control','mount','lock'],to:null,cost:-28,focus:-8,power:8,grip:0,base:0,control:0,belt:'Branca'}
  ]},
  missions:{missions:[{id:'tutorial_01',title:'Primeiro Sparring no Terreiro',arena_id:'terreiro',opponent_id:'davi_relampago',axis:'honra',reward:{money:80,xp:20,honra:3,hype:2,sombra:0}}]},
  arenas:{arenas:[{id:'terreiro',name:'Terreiro da Luta'}]},
  live:{posts:[{author:'Cria Live',text:'Ruan treinou no silêncio. Quem viu, respeitou.',tone:'honra',honra:2,hype:1,sombra:0}]}
};

const q = s => document.querySelector(s);
const clamp = (v,min,max) => Math.max(min, Math.min(max, v));
const pct = (v,m=100) => clamp(Math.round((v/m)*100),0,100);
const cp = v => JSON.parse(JSON.stringify(v));
const rnd = (a,b) => Math.random()*(b-a)+a;
const one = arr => arr[Math.floor(Math.random()*arr.length)];

class Game {
  constructor(){
    this.el = q('#app');
    this.data = cp(fallback);
    this.state = this.load() || this.fresh();
    this.view = 'hub';
    this.match = null;
  }

  async init(){
    await this.loadData();
    document.body.addEventListener('click', e => this.click(e));
    this.note('Sistema pronto. O tatame abriu.');
    this.render();
  }

  fresh(){
    return {week:1,day:0,money:120,energy:82,belt:'Branca',xp:0,honra:50,hype:10,sombra:0,unlocked:['clinch','baiana','passagem','montada','respirar'],log:[],feed:[]};
  }

  async loadData(){
    const pairs = await Promise.all(Object.entries(DATA).map(async ([k,u])=>{
      try{const r=await fetch(u,{cache:'no-store'}); if(!r.ok) throw Error(u); return [k, await r.json()];}
      catch{return [k, fallback[k]];}
    }));
    this.data = Object.fromEntries(pairs);
  }

  load(){try{return JSON.parse(localStorage.getItem(STORE));}catch{return null;}}
  save(){localStorage.setItem(STORE, JSON.stringify({...this.state,saved_at:new Date().toISOString()})); this.note('Save concluído.'); this.render();}
  reset(){localStorage.removeItem(STORE); this.state=this.fresh(); this.match=null; this.note('Novo ciclo iniciado.'); this.render();}
  note(t){this.state.log=[`${DAYS[this.state.day]} • ${t}`,...(this.state.log||[])].slice(0,12);}

  click(e){
    const b=e.target.closest('button'); if(!b) return;
    if(b.dataset.nav){ if(b.dataset.nav==='save') return this.save(); this.view=b.dataset.nav; return this.render(); }
    const a=b.dataset.action, id=b.dataset.id;
    if(a==='train') this.train(id);
    if(a==='rest') this.rest();
    if(a==='mission') this.start(id);
    if(a==='tech') this.tech(id);
    if(a==='post') this.post();
    if(a==='reset') this.reset();
    if(a==='hub'){this.view='hub'; this.render();}
  }

  chars(){return this.data.characters.characters||fallback.characters.characters;}
  ruan(){return this.chars().find(c=>c.id==='ruan_macacao')||this.chars()[0];}
  char(id){return this.chars().find(c=>c.id===id)||this.chars()[1]||this.chars()[0];}
  mission(id){return (this.data.missions.missions||fallback.missions.missions).find(m=>m.id===id)||fallback.missions.missions[0];}
  arena(id){return (this.data.arenas.arenas||fallback.arenas.arenas).find(a=>a.id===id)||fallback.arenas.arenas[0];}
  techs(){return this.data.techniques.techniques||fallback.techniques.techniques;}

  train(kind='drill'){
    const plan = {drill:[12,14,'drilling'],spar:[18,22,'sparring'],grip:[14,18,'grip']}[kind] || [12,14,'drilling'];
    if(this.state.energy < plan[1]){this.note('Energia baixa. Descanse.'); return this.render();}
    this.state.energy=clamp(this.state.energy-plan[1],0,100); this.state.xp+=plan[0]; this.state.honra=clamp(this.state.honra+1,0,100);
    this.note(`Treino feito: ${plan[2]}. XP +${plan[0]}.`); this.promote(); this.day(false); this.save();
  }

  rest(){this.state.energy=clamp(this.state.energy+32,0,100); this.state.honra=clamp(this.state.honra+1,0,100); this.note('Descanso feito.'); this.day(false); this.save();}
  day(render=true){this.state.day++; if(this.state.day>=7){this.state.day=0; this.state.week++; this.state.energy=clamp(this.state.energy+18,0,100); this.note(`Semana ${this.state.week} começou.`);} if(render)this.render();}
  promote(){const n={Branca:70,Azul:160,Roxa:290,Marrom:440}; if(n[this.state.belt] && this.state.xp>=n[this.state.belt]){this.state.belt=BELTS[BELTS.indexOf(this.state.belt)+1]; this.note(`Graduação: faixa ${this.state.belt}.`); this.state.unlocked=[...new Set([...this.state.unlocked,...this.techs().filter(t=>BELTS.indexOf(t.belt||t.min_belt||'Branca')<=BELTS.indexOf(this.state.belt)).map(t=>t.id)])];}}

  fighter(c){return {id:c.id,name:`${c.name} “${c.nickname||''}”`,stats:cp(c.stats),hp:c.stats.hp,maxHp:c.stats.hp,stamina:c.stats.stamina,maxStamina:c.stats.stamina,grip:100,base:100,focus:c.stats.focus};}
  start(id){const m=this.mission(id), r=this.ruan(), o=this.char(m.opponent_id); this.match={mission:m,arena:this.arena(m.arena_id),pos:'standup',control:0,round:1,done:false,player:this.fighter(r),rival:this.fighter(o),log:[`Missão iniciada: ${m.title}.`]}; this.view='combat'; this.render();}
  available(){if(!this.match)return []; return this.techs().filter(t=>this.state.unlocked.includes(t.id)&&BELTS.indexOf(t.belt||t.min_belt||'Branca')<=BELTS.indexOf(this.state.belt)&&(t.from||[]).includes(this.match.pos));}

  tech(id){
    if(!this.match||this.match.done)return; const t=this.techs().find(x=>x.id===id); if(!t)return; const p=this.match.player, r=this.match.rival;
    if(t.cost>0 && p.stamina<t.cost){this.match.log.unshift('Sem gás para executar.'); return this.render();}
    p.stamina=clamp(p.stamina-t.cost,0,p.maxStamina); p.focus=clamp(p.focus-(t.focus||t.focus_cost||0),0,100);
    if((t.type||'')==='recover'||t.cost<0){p.stamina=clamp(p.stamina+Math.abs(t.cost),0,p.maxStamina); p.focus=clamp(p.focus+Math.abs(t.focus||t.focus_cost||0),0,100); p.base=clamp(p.base+10,0,100); this.match.log.unshift('Ruan respirou e firmou base.'); this.reply(); return this.render();}
    const atk=p.stats.technique+p.stats.pressure*.45+p.stats.grip_strength*.35+p.focus*.25+(t.power||0)+rnd(0,28);
    const def=r.stats.technique+r.stats.speed*.25+r.base*.3+r.focus*.22+rnd(0,42);
    if(atk>=def){const bonus=p.id==='ruan_macacao'?1.15:1; r.grip=clamp(r.grip-Math.round((t.grip||0)*bonus),0,100); r.base=clamp(r.base-(t.base||0),0,100); r.stamina=clamp(r.stamina-Math.round((t.base||0)*.45),0,r.maxStamina); this.match.control=clamp(this.match.control+(t.control||0),0,100); if(t.to)this.match.pos=t.to; this.match.log.unshift(`✅ ${t.name} encaixou. Posição: ${POS[this.match.pos]||this.match.pos}.`);} else {p.base=clamp(p.base-6,0,100); this.match.log.unshift(`⚠️ ${t.name} foi neutralizada.`);}
    if(this.match.control>=100 || (r.grip<=0 && this.match.pos==='lock')) return this.win();
    this.reply(); this.match.round++; this.render();
  }

  reply(){const p=this.match.player,r=this.match.rival; if(r.stamina<18){r.stamina=clamp(r.stamina+20,0,r.maxStamina); this.match.log.unshift(`${r.name} recuperou fôlego.`); return;} r.stamina=clamp(r.stamina-14,0,r.maxStamina); if(r.stats.technique+r.stats.speed*.35+rnd(0,34)>p.stats.technique+p.base*.3+p.focus*.28+rnd(0,38)){p.hp=clamp(p.hp-Math.round(rnd(5,13)),0,p.maxHp); p.base=clamp(p.base-Math.round(rnd(5,12)),0,100); this.match.log.unshift(`${r.name} criou pressão e Ruan perdeu pontos técnicos.`);} else {r.grip=clamp(r.grip-6,0,100); this.match.log.unshift('Ruan leu a intenção e travou a sequência.');} if(p.hp<=0||p.base<=0)this.loss();}
  win(){const rew=this.match.mission.reward||{}; this.match.done=true; this.state.money+=rew.money||0; this.state.xp+=rew.xp||0; this.state.honra=clamp(this.state.honra+(rew.honra||0),0,100); this.state.hype=clamp(this.state.hype+(rew.hype||0),0,100); this.state.sombra=clamp(this.state.sombra+(rew.sombra||0),0,100); this.match.log.unshift(`🏆 Vitória. R$${rew.money||0}, XP +${rew.xp||0}.`); this.note(`Vitória em ${this.match.mission.title}.`); this.post(true); this.promote(); this.day(false); this.save();}
  loss(){this.match.done=true; this.state.honra=clamp(this.state.honra+2,0,100); this.state.hype=clamp(this.state.hype-3,0,100); this.state.energy=clamp(this.state.energy-12,0,100); this.match.log.unshift('Derrota limpa. Volte ao treino.'); this.note('Ruan perdeu e aprendeu.'); this.day(false); this.save();}
  post(silent=false){const post=one(this.data.live.posts||fallback.live.posts); this.state.feed=[post,...(this.state.feed||[])].slice(0,10); this.state.honra=clamp(this.state.honra+(post.honra||0),0,100); this.state.hype=clamp(this.state.hype+(post.hype||0),0,100); this.state.sombra=clamp(this.state.sombra+(post.sombra||0),0,100); if(!silent){this.note(`Cria Live: ${post.text}`); this.save();}}

  bar(label,v,m,type=''){return `<div><div class="row" style="justify-content:space-between"><span class="stat-label">${label}</span><span class="stat-label">${Math.round(v)}/${m}</span></div><div class="bar-wrap"><div class="bar ${type}" style="width:${pct(v,m)}%"></div></div></div>`;}
  stat(l,v,t=''){return `<div class="card"><div class="stat-label">${l}</div><div class="stat-value">${v}</div>${t?`<p class="muted">${t}</p>`:''}</div>`;}
  render(){this.el.innerHTML = this.view==='train'?this.trainView():this.view==='combat'?this.combatView():this.view==='live'?this.liveView():this.hubView();}
  hubView(){return `<section class="hero"><div class="panel"><div class="kicker">Action RPG BJJ • Sprint 0</div><h1 class="title-xl">RUAN <span class="brush">MACACÃO</span></h1><p class="muted">Protótipo jogável com treino, partida posicional, reputação, Cria Live, save/load e JSON.</p><div class="row"><button data-nav="train">Treinar</button><button data-action="mission" data-id="tutorial_terreiro_01">Primeiro sparring</button><button class="ghost" data-nav="live">Cria Live</button></div></div><aside class="panel"><span class="badge">Terreiro da Luta</span><h2>Semana ${this.state.week} • ${DAYS[this.state.day]}</h2><div class="grid two">${this.stat('Faixa',this.state.belt)}${this.stat('XP',this.state.xp)}${this.stat('Energia',this.state.energy+'%')}${this.stat('Dinheiro','R$'+this.state.money)}</div></aside></section><section class="grid three" style="margin-top:1rem">${this.stat('Honra',this.state.honra)}${this.stat('Hype',this.state.hype)}${this.stat('Sombra',this.state.sombra)}</section><section class="panel" style="margin-top:1rem"><h2>Registro</h2><div class="log">${(this.state.log||[]).map(i=>`<p>${i}</p>`).join('')||'<p>Nenhum evento ainda.</p>'}</div><div class="row" style="margin-top:1rem"><button class="ghost danger" data-action="reset">Apagar save</button></div></section>`;}
  trainView(){return `<section class="panel"><div class="kicker">Treino semanal</div><h1>Escolha o trabalho.</h1><div class="grid three"><div class="card"><h3>Drilling</h3><p>XP +12 • Energia -14</p><button data-action="train" data-id="drill">Treinar</button></div><div class="card"><h3>Sparring</h3><p>XP +18 • Energia -22</p><button data-action="train" data-id="spar">Treinar</button></div><div class="card"><h3>Grip</h3><p>XP +14 • Energia -18</p><button data-action="train" data-id="grip">Treinar</button></div></div><div class="row" style="margin-top:1rem"><button class="ghost" data-action="rest">Descansar</button></div></section>`;}
  combatView(){if(!this.match){return `<section class="panel"><h1>Mapa de partidas</h1><div class="grid two">${(this.data.missions.missions||[]).map(m=>`<div class="card"><span class="badge">${m.axis||m.moral_axis}</span><h3>${m.title}</h3><p class="muted">${this.arena(m.arena_id).name} • Rival: ${this.char(m.opponent_id).name}</p><button data-action="mission" data-id="${m.id}">Iniciar</button></div>`).join('')}</div></section>`;} const c=this.match; return `<section class="combat-layout"><aside class="fighter-card"><span class="badge">${this.state.belt}</span><h2>${c.player.name}</h2>${this.bar('Vida',c.player.hp,c.player.maxHp,'hp')}${this.bar('Stamina',c.player.stamina,c.player.maxStamina,'stamina')}${this.bar('Grip',c.player.grip,100,'grip')}${this.bar('Base',c.player.base,100,'base')}${this.bar('Foco',c.player.focus,100,'focus')}</aside><section class="tatame-stage"><div><div class="fighter-token">🦍🥋</div><h2>${POS[c.pos]||c.pos}</h2><p class="muted">${c.arena.name} • Round ${c.round} • Controle ${c.control}%</p></div></section><aside class="fighter-card"><span class="badge">Rival</span><h2>${c.rival.name}</h2>${this.bar('Vida',c.rival.hp,c.rival.maxHp,'hp')}${this.bar('Stamina',c.rival.stamina,c.rival.maxStamina,'stamina')}${this.bar('Grip',c.rival.grip,100,'grip')}${this.bar('Base',c.rival.base,100,'base')}${this.bar('Foco',c.rival.focus,100,'focus')}</aside></section><section class="grid two" style="margin-top:1rem"><div class="panel"><h2>Técnicas</h2><div class="tech-list">${this.available().map(t=>`<button class="tech-btn" data-action="tech" data-id="${t.id}" ${c.done?'disabled':''}><span>${t.name}<br><small>Custo ${Math.max(t.cost,0)}</small></span><span>›</span></button>`).join('')||'<p class="muted">Nenhuma técnica disponível.</p>'}</div><div class="row" style="margin-top:1rem"><button class="ghost" data-action="hub">Voltar ao hub</button>${c.done?'<button data-nav="combat">Nova partida</button>':''}</div></div><div class="panel"><h2>Log</h2><div class="log">${c.log.slice(0,9).map(i=>`<p>${i}</p>`).join('')}</div></div></section>`;}
  liveView(){const feed=this.state.feed.length?this.state.feed:this.data.live.posts; return `<section class="panel"><div class="kicker">Cria Live</div><h1>Reputação é recurso.</h1><p class="muted">Posts offline validados. IA entra só como geradora de JSON.</p><button data-action="post">Publicar repercussão</button></section><section class="grid two" style="margin-top:1rem">${feed.map(p=>`<article class="feed-card"><strong>${p.author}</strong><p>${p.text}</p><small>tom: ${p.tone||'neutral'} • honra ${p.honra||0} • hype ${p.hype||0} • sombra ${p.sombra||0}</small></article>`).join('')}</section>`;}
}

window.addEventListener('DOMContentLoaded',()=>{const game=new Game(); window.criaDoTatame=game; game.init();});
