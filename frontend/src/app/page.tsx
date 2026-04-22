import { StatusCard } from "@/components/status-card";

const cards = [
  {
    titulo: "Estado da API",
    valor: "Online",
    descricao: "Healthcheck disponível em /api/v1/health/live",
    destaque: true,
  },
  {
    titulo: "Fallback de Modalidade",
    valor: "Ativo",
    descricao: "Endpoint pronto: /api/v1/modality/override",
  },
  {
    titulo: "Overlay OBS",
    valor: "Pronto",
    descricao: "Rota dedicada em /overlay/live com layout transparente",
  },
];

export default function HomePage() {
  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_#0f172a,_#020617_60%)] p-8 lg:p-14">
      <section className="mx-auto max-w-6xl">
        <p className="inline-flex rounded-full border border-emerald-400/40 bg-emerald-500/10 px-4 py-1 text-sm text-emerald-300">
          Etapa 1 · Base de Produção
        </p>
        <h1 className="mt-6 text-4xl font-black tracking-tight text-white lg:text-5xl">Visão de Cria</h1>
        <p className="mt-4 max-w-2xl text-lg text-slate-300">
          Plataforma de análise de combate com arquitetura modular para Boxe, MMA e Jiu-Jitsu Gi/No-Gi.
        </p>

        <div className="mt-10 grid gap-5 md:grid-cols-3">
          {cards.map((card) => (
            <StatusCard key={card.titulo} {...card} />
          ))}
        </div>
      </section>
    </main>
  );
}
