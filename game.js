const roster = [
  ["01","Ruan Macacão","Pressão • top game","ruan_macacao","idle","Silverback Grip"],
  ["02","Davi Relâmpago","Velocidade • contra-ataque","davi_relampago","idle","Scramble técnico"],
  ["03","Mestre Dendê","Base • disciplina","mestre_dende","teaching","Pressão segura"],
  ["04","Tinker Bell","Leitura • timing","tinker_bell","recording","Análise tática"],
  ["05","Cássio Molho","Hype • tentação","cassio_molho","provocation","Pressão da torcida"],
  ["06","Kenzo Kuroi","Precisão • sombra","kenzo_kuroi","counter","Contra-ataque frio"],
  ["07","Leoa Quilombola","Raiz • resistência","leoa_quilombola","sweep_setup","Raspagem ancestral"],
  ["08","Oni da Lapa","Intimidação • caos","oni_da_lapa","pressure","Montada sombria"]
];

document.querySelector("#rosterGrid").innerHTML = roster.map(([n,name,style,id,action,signature]) => `
  <article class="fighter-card">
    <header><span class="index">${n}</span><h3>${name}</h3><p>${style}</p></header>
    <img loading="lazy" src="./assets/sprites/${id}/${action}/preview.gif" alt="Rig técnico animado de ${name}">
    <footer><span>HD PIXEL 2.5D</span><span>${signature}</span></footer>
  </article>`).join("");

const state = {step:0,hp:100,gas:100,focus:100,daviHp:100,daviGas:100,daviFocus:100,control:12,grip:100};
const el = id => document.getElementById(id);
const actions = {
  grip:{position:"DISPUTA DE PEGADA",message:"Ruan fecha manga e gola. Silverback Grip drena a integridade da pegada adversária.",gas:-7,focus:-3,control:12,grip:-15,clip:"grip"},
  baiana:{position:"QUEDA • ENTRADA",message:"Mudança de nível, cabeça alinhada e peso comprometido. Davi precisa defender a base.",gas:-14,focus:-6,control:24,grip:-8,clip:"baiana_entry",daviGas:-9},
  pressure:{position:"CHÃO • CEM QUILOS",message:"Controle lateral estabilizado. O cronômetro técnico confirma domínio antes de pontuar.",gas:-9,focus:-4,control:31,grip:-5,clip:"cem_quilos_control",daviGas:-12},
  defense:{position:"DEFESA • BASE",message:"Ruan recompõe cotovelos e joelhos, preserva o pescoço e volta a respirar.",gas:7,focus:5,control:-10,grip:3,clip:"idle"},
  finish:{position:"FINALIZAÇÃO • CONTROLE",message:"Janela técnica aberta: setup, lock, pressão controlada e resposta de tap ou escape.",gas:-12,focus:-12,control:20,grip:-10,clip:"tap_reset",daviHp:-22}
};

function clamp(v){return Math.max(0,Math.min(100,v));}
function setWidth(id,value){el(id).style.width=`${clamp(value)}%`;}
function replay(img,path){img.src=`${path}?v=${Date.now()}`;}
function render(){
  setWidth("ruanHp",state.hp);setWidth("ruanGas",state.gas);setWidth("ruanFocus",state.focus);
  setWidth("daviHp",state.daviHp);setWidth("daviGas",state.daviGas);setWidth("daviFocus",state.daviFocus);
  el("controlValue").textContent=`${clamp(state.control)}%`;el("gripValue").textContent=`${clamp(state.grip)}%`;
  document.querySelector('[data-action="finish"]').disabled=state.control<55;
}

document.querySelectorAll("[data-action]").forEach(button=>button.addEventListener("click",()=>{
  const key=button.dataset.action,action=actions[key];
  state.gas=clamp(state.gas+(action.gas||0));state.focus=clamp(state.focus+(action.focus||0));state.control=clamp(state.control+(action.control||0));state.grip=clamp(state.grip+(action.grip||0));state.daviGas=clamp(state.daviGas+(action.daviGas||-3));state.daviHp=clamp(state.daviHp+(action.daviHp||0));
  el("position").textContent=action.position;el("fightMessage").textContent=action.message;
  document.querySelectorAll("[data-action]").forEach(b=>b.classList.remove("active"));button.classList.add("active");
  replay(el("ruanSprite"),`./assets/sprites/ruan_macacao/${action.clip}/preview.gif`);
  el("arenaStage").animate([{filter:"brightness(1.28)"},{filter:"brightness(1)"}],{duration:180});
  render();
}));

render();
if("serviceWorker" in navigator){window.addEventListener("load",()=>navigator.serviceWorker.register("./sw.js").catch(()=>{}));}
