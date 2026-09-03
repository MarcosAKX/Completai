# DESIGN.md — CompletAI

> Padrão visual derivado das telas de referência fornecidas (login, cadastro,
> recuperação de senha, seleção de perfil, cadastro de posto). Toda tela nova
> segue este documento. Atualiza `core/theme/app_colors.dart`.

## Paleta (extraída por amostragem de pixel das referências, não estimada)

| Token | Hex | Uso |
|---|---|---|
| `primary` | `#325DFB` | Botões primários, links, ícones de destaque, indicador de progresso |
| `primaryLight` | `#E8EEFF` | Fundo do herói/card destacado (tela de login) |
| `screenBackground` | `#F6F7F9` | Fundo padrão das telas secundárias (cadastro, recuperar senha) |
| `surface` | `#FFFFFF` | Cards, inputs |
| `onSurface` | `#1B1E28` | Texto principal |
| `textSecondary` | `#6B7280` | Subtítulos, texto de apoio, placeholder |
| `outline` | `#E3E6EC` | Borda de input |

## Padrões de tela identificados

### 1. Tela "hero + card" (login)
- Bloco superior azul (`primaryLight` de fundo, elementos `primary`) com
  ilustração simples de linha (SVG), **altura proporcional à tela**
  (`MediaQuery.height * ~0.22`), nunca pixel fixo — ver nota de responsividade
  abaixo.
- Card branco com cantos arredondados (`~24px`) sobrepondo levemente o herói,
  contendo o formulário.
- **Regra de ouro, baseada no problema identificado na referência 1**: todo o
  conteúdo do card deve caber sem cortar o(s) botão(ões) de ação secundária
  (ex: "Criar conta"). Isso é obtido com hero compacto (sem headline grande
  empilhado com ilustração) + `SingleChildScrollView` como rede de segurança
  para aparelhos com tela pequena.

### 2. Tela "AppBar simples + card" (recuperar senha, formulários com voltar)
- Fundo `screenBackground`.
- `AppBar` transparente com seta de voltar + título, sem elevação.
- Ícone circular de destaque (fundo `primaryLight`, ícone `primary`) acima do
  título da tela.
- Título grande (`AppTextStyles.title`), subtítulo em `textSecondary`.
- Card branco com o formulário, ou formulário direto na tela (ver seção 3).

### 3. Tela de cadastro em etapas (cadastro de posto)
- Indicador "Etapa X de Y" + barra de progresso linear com círculos nas
  extremidades (`primary` preenchido até a etapa atual, cinza claro no
  restante).
- Mesmo padrão de ícone circular + título + subtítulo da seção 2.
- Inputs em lista vertical, sem agrupar em card (fundo já é
  `screenBackground`, os próprios campos brancos já se destacam).
- Botão primário de ação no rodapé (`Próximo`/`Finalizar Cadastro`).

### 4. Cards de seleção (escolha de perfil: Motorista / Posto)
- Card branco, cantos arredondados, leve sombra.
- Ícone à esquerda em container quadrado arredondado com fundo
  `primaryLight` e ícone `primary`.
- Título em negrito + descrição em `textSecondary` à direita do ícone.
- Toda a área do card é clicável (não só o ícone).

## Componentes (tokens de `core/widgets/`)

- **`AppButton`** (já existe): manter, mas confirmar `borderRadius` alto
  (pill-like, ~28px ou metade da altura) para bater com a referência —
  botões nas imagens são bem arredondados, não levemente arredondados.
- **`AppTextField`** (já existe): confirmar ícone à esquerda (prefixIcon),
  borda `outline` (#E3E6EC), cantos arredondados (~14px), label acima do
  campo (não flutuante dentro do campo).
- **Novo: `AppSelectionCard`** — para a tela de escolha de perfil (seção 4).
- **Novo: `AppStepProgress`** — indicador "Etapa X de Y" com barra (seção 3).
- **Novo: `AppIconBadge`** — círculo/quadrado arredondado com ícone
  (reutilizado nas seções 2, 3 e 4).

## Responsividade — regra técnica obrigatória

Esta seção existe porque a referência 1 (tela de login com headline grande)
não cabia na tela e cortava o botão "Criar conta". Para evitar repetir isso:

1. **Nenhuma altura de hero/ilustração em pixel fixo.** Use fração de
   `MediaQuery.of(context).size.height` ou `LayoutBuilder`.
2. **Todo formulário de tela fica dentro de `SingleChildScrollView`**, mesmo
   quando o design não parece precisar — é a rede de segurança para telas
   pequenas (Android com resolução baixa, comum no público-alvo do TCC).
3. **Textos de apoio longos (headline + subtítulo) não empilham com
   ilustração no mesmo bloco fixo** — se o design pedir os dois, o bloco
   precisa ser flexível (`Flexible`/`Expanded` dentro de `Column`), não
   `Container` de altura fixa.
4. Teste mental obrigatório antes de considerar uma tela pronta: "isso cabe
   numa tela de 5.5 polegadas, resolução baixa, sem cortar nenhum botão de
   ação?" — se a resposta não for óbvia, rode no emulador com um dispositivo
   pequeno antes de aprovar.
