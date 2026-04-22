interface StatusCardProps {
  titulo: string;
  valor: string;
  descricao: string;
  destaque?: boolean;
}

export function StatusCard({ titulo, valor, descricao, destaque = false }: StatusCardProps) {
  return (
    <article
      className={[
        "rounded-2xl border p-5 shadow-xl backdrop-blur",
        destaque ? "border-emerald-400/70 bg-emerald-950/35" : "border-slate-700/70 bg-slate-900/55",
      ].join(" ")}
    >
      <p className="text-sm uppercase tracking-wide text-slate-300">{titulo}</p>
      <p className="mt-2 text-2xl font-bold text-white">{valor}</p>
      <p className="mt-2 text-sm text-slate-300">{descricao}</p>
    </article>
  );
}
