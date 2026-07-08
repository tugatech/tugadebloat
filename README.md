# TugaDebloat - Windows 11 Optimizer & Debloater

O **TugaDebloat** é uma ferramenta gráfica avançada, desenvolvida inteiramente em PowerShell, focada em otimizar o desempenho, aumentar a privacidade e remover o *bloatware* do Windows 11.

Criado pela comunidade [TugaTech](https://tugatech.com.pt) para oferecer aos utilizadores e administradores de sistemas um controlo total e transparente sobre o sistema operativo.

---

## 🚀 Funcionalidades Principais

Este *script* agrupa mais de 100 otimizações distintas, organizadas numa interface simples e intuitiva. As principais áreas de atuação incluem:

*   **Privacidade e Telemetria:** Bloqueio do envio de dados de diagnóstico (DiagTrack), desativação da Cortana, bloqueio global de hardware (câmara/microfone para apps UWP) e restrição da recolha de dados de digitação.
*   **Debloat Profundo:** Remoção segura de dezenas de aplicações pré-instaladas (TikTok, Spotify, Instagram, integrações Xbox) e limpeza de pacotes provisionados órfãos para evitar que voltem após uma atualização.
*   **Desempenho Extremo:** Ativação do plano *Ultimate Performance*, desativação de apps em segundo plano, otimização da *cache* NTFS (Disable 8dot3) e ajustes no agendamento de CPU.
*   **Interface Clássica:** Restauro do menu de contexto clássico do Windows 10, remoção de atrasos visuais (Aero Peek, animações) e alinhamento da barra de tarefas.
*   **Rede e DNS:** Sistema exclusivo para seleção rápida de servidores DNS over HTTPS (DoH) - como Cloudflare, Control D, AdGuard e Quad9 - com proteção contra seleção múltipla. Otimização do algoritmo de Nagle (TCP) para redução de latência em jogos e redes.
*   **Gestão de Serviços:** Desativação de serviços desnecessários para libertar memória e ciclos de CPU (Print Spooler, Fax, Xbox Services, Indexação).

---

## 🛠️ Como Executar

Por predefinição, o Windows bloqueia a execução de *scripts* de terceiros que não estejam assinados digitalmente. Para correr o **TugaDebloat** de forma segura, siga os passos abaixo:

1. Faça o *download* ou clone este repositório para o seu computador.
2. Abra o **PowerShell como Administrador**.
3. Navegue até à pasta onde guardou o ficheiro (ex: `cd C:\Users\O-Seu-Nome\Downloads`).
4. Ative temporariamente a execução de *scripts* na sessão atual colando o seguinte comando:

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

   *(Pressione **S** ou **Y** e Enter se for pedida confirmação).*

5. Execute o *script*:

   ```powershell
   .\debloat-tuga.ps1
   ```

*(Nota: Como definimos o escopo apenas para o processo atual, assim que fechar a janela do PowerShell, as políticas de segurança do Windows regressam automaticamente ao seu estado protegido original).*

---

## 🛡️ Segurança e Recomendações

O TugaDebloat foi criado para ser transparente (o utilizador pode ver no painel inferior o detalhe técnico do que cada opção altera no sistema). 

**Ponto de Restauro:** Ao iniciar a ferramenta, será questionado se pretende criar um Ponto de Restauro do sistema. É **altamente recomendado** que selecione "Sim", para garantir que pode reverter qualquer configuração caso uma aplicação específica que utilize deixe de funcionar.

---

## 👨‍💻 Créditos

Desenvolvido para a comunidade **TugaTech** - por [@DJPRMF](https://github.com/DJPRMF).
Para mais dicas, análises e guias de tecnologia, visite: [tugatech.com.pt](https://tugatech.com.pt)

**Licença:** Distribuído de forma aberta para a comunidade. Use por sua conta e risco.

**Nota:** Qualquer issue ou tópico criado com referência ao nome "pouco original" ou "boring" para o script vale um café.
