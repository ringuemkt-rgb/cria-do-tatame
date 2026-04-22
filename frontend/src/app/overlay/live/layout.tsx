"use client";

import { useEffect } from "react";

export default function OverlayLayout({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    document.body.classList.add("overlay-obs");
    return () => document.body.classList.remove("overlay-obs");
  }, []);

  return children;
}
