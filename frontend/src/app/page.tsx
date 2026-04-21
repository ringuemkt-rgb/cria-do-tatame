export default function HomePage() {
  return (
    <main className="min-h-screen p-8">
      <h1 className="text-3xl font-bold">Visão de Cria</h1>
      <p className="mt-4 text-lg text-slate-300">
        Etapa 1 concluída: infraestrutura, backend FastAPI e frontend Next.js prontos.
      </p>
      <ul className="mt-6 list-disc pl-6 text-slate-200">
        <li>API base em /api/v1/health</li>
        <li>Fallback de modalidade em /api/v1/modality/override</li>
        <li>Overlay OBS em /overlay/live</li>
      </ul>
    </main>
  );
}
