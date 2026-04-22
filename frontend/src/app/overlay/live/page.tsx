export default function OverlayLivePage() {
  return (
    <main className="flex min-h-screen items-start justify-between p-5 text-lg">
      <section className="max-w-md rounded-2xl border border-emerald-400/70 bg-black/60 p-4 shadow-2xl backdrop-blur-sm">
        <p className="text-xs uppercase tracking-wider text-emerald-300">Overlay OBS · tempo real</p>
        <h2 className="mt-1 text-xl font-bold text-white">🥋 Visão de Cria</h2>
        <p className="mt-2 text-slate-200">Aguardando detecção automática de modalidade (3-5 segundos iniciais).</p>
        <div className="mt-4 rounded-lg border border-slate-700 bg-slate-900/70 p-3 text-sm text-slate-200">
          ✅ Sistema pronto para receber stream.
        </div>
      </section>

      <aside className="rounded-xl border border-sky-400/60 bg-black/60 px-4 py-3 text-sm text-sky-200">
        Modo Análise Técnica: <strong>Desativado</strong>
      </aside>
    </main>
  );
}
