🔮 Code Orbs: A Jornada pelos Dados
📌 Sobre o Projeto
O Code Orbs é um jogo educativo desenvolvido para desmistificar os conceitos mais fundamentais da computação: Tipos de Dados e Variáveis.

Muitas vezes, iniciantes em programação desistem devido à alta carga de abstração inicial. O Code Orbs transforma essa abstração em mecânicas visuais, onde o jogador manipula orbes de energia (dados) e os organiza em recipientes (variáveis). Baseado na Arquitetura de Von Neumann e na Teoria de Tipos de Pierce, o jogo cria uma ponte entre a ação lúdica e a sintaxe real em Python.

🎮 Mecânicas Principais
Sistema de Orbes: Cada cor e forma representa um tipo de dado (int, float, string, etc.).

Recipientes de Memória: Representação visual de variáveis onde o jogador deve respeitar a tipagem para resolver puzzles.

Console em Tempo Real: Toda ação no jogo gera uma linha de código Python correspondente, permitindo o aprendizado por observação.

Feedback Educativo: Erros de tipagem geram respostas visuais amigáveis, incentivando o ciclo de aprendizagem de Kolb.

🚀 Tecnologias Utilizadas
Godot Engine: Motor gráfico para a interface e interatividade.

GDScript: Utilizado para a lógica interna do jogo devido à sua semelhança com Python.

Python: Linguagem alvo utilizada no console educativo do jogo.
Por enquanto so tem o projeto do godot, ou seja tem que baixar o godot 4.4
https://godotengine.org/download/archive

## CI / Builds (GitHub Actions)

O workflow `.github/workflows/godot-ci.yml` exporta o jogo com Godot **4.4**:

| Evento | Resultado |
|---|---|
| Push / PR / tag | **Smoke test** headless (abre o projeto; se der erro de script, o build para) |
| Push / PR em `main` ou `master` | Artifacts `windows` e `linux` na aba **Actions** |
| Build OK na `main`/`master` | **Tag automática** `v*` via `auto-tag.yml` → Release com ZIPs |
| Tag `v*` (ex.: `v1.0.1`) | **GitHub Release** com ZIPs de Windows e Linux |

Usa a imagem [abarichello/godot-ci](https://github.com/abarichello/godot-ci) (`barichello/godot-ci:4.4`).  
Os presets estão em `export_presets.cfg` (precisa estar versionado).  
Android já tem preset no projeto; o job no workflow está comentado para ativar depois com keystore via secrets.

### Versionamento (automático)

O *Auto tag release* lê as mensagens **desde a última tag** (Conventional Commits):

| Prefixo no commit | Bump | Exemplo |
|---|---|---|
| `feat:` | **minor** | `v1.0.0` → `v1.1.0` |
| `fix:` / `chore:` / `ci:` / sem prefixo | **patch** | `v1.0.0` → `v1.0.1` |
| `BREAKING CHANGE:` ou `feat!:` / `fix!:` | **major** | `v1.0.0` → `v2.0.0` |

Exemplos: `feat: adiciona QR no criador`, `fix: corrige crash no slot`.  
Se houver `feat:` e `fix:` no mesmo intervalo, vale o **maior** bump (minor).

**Fluxo:** merge na `main` → Build passa → tag criada → Release com ZIPs.  
**Manual:** Actions → *Auto tag release* → Run workflow (`auto` / `patch` / `minor` / `major`).  
**Pular release:** `[skip release]` na mensagem do commit.
