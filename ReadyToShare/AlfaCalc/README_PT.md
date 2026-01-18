# AlfaCalc - Motor de Cálculo de Alta Precisão e Escala Infinita

A **AlfaCalc** é uma ferramenta de computação de nível profissional desenvolvida para operações aritméticas de alta performance com precisão numérica virtualmente ilimitada. Serve como uma ponte especializada entre três sistemas de numeração distintos, oferecendo sincronização em tempo real e uma interface robusta baseada no sistema "Infinity Display".

Desenvolvida pela **JTR Software**, a AlfaCalc materializa a nossa filosofia:  
> *"É simples parecer complicado, o complicado é parecer simples."*

---

## 🚀 Conjunto de Funcionalidades Avançadas

### 1. Arquitetura "Infinity Display"
As etiquetas GUI padrão falham ao tentar renderizar milhares de dígitos. A AlfaCalc resolve este problema utilizando um sistema de `TEdit` customizados (Decimal, Hex e Alfa) que oferece:
- **Scroll Horizontal Fluido**: Navegue por milhões de dígitos usando as teclas de seta ou o arrasto do rato.
- **Capacidade de Copiar/Colar**: Copie diretamente valores extremamente grandes para utilizar noutras ferramentas científicas ou de engenharia.
- **Renderização Sem Glitches**: Eliminação de cortes visuais ou artefactos típicos das Labels padrão do Windows quando os números excedem a largura do ecrã.

### 2. Motor Sincronizado Triple-Base
Realize um cálculo numa base e veja a conversão nas outras duas instantaneamente:
- **Decimal (Base-10)**: Aritmética padrão [0-9].
- **Hexadecimal (Base-16)**: Suporte a [0-9][A-F] para aplicações em informática e sistemas embebidos.
- **Alfadecimal (Base-36)**: Suporte total de [0-9][A-Z], permitindo uma representação numérica densa e compacta.

### 3. Aritmética de Disco "Swap"
Quando os números se tornam demasiado grandes para os buffers de memória padrão, a AlfaCalc pode utilizar o seu sistema único de **Memória Swap**:
- Processa aritmética utilizando fluxos de ficheiros temporários (`TFileStream`).
- Permite cálculos que normalmente causariam crash em calculadoras comuns devido ao transbordo de RAM.
- *Nota: Suporta cálculos de multi-gigabytes neste modo.*

### 4. Performance e o "Modo Turbo"
A computação científica exige muitos recursos. A AlfaCalc inclui um seletor de performance (**Checkbox Conversão Automática**):
- **Ativado**: Todas as três bases atualizam-se em tempo real enquanto digita (ideal para valores pequenos e médios).
- **Desativado (Turbo)**: Apenas o visor ativo atualiza, mostrando `🚫` nos inativos para priorizar os ciclos de CPU para o cálculo principal. A conversão ocorre sob demanda ao mudar de base.

---

## ⌨️ Interface de Teclado (Atalhos)

A AlfaCalc foi desenhada para "Power Users" e dactilógrafos:
- **Introdução Numérica**: `0-9`, `A-F` (Hex), `G-Z` (Alfa).
- **Separador Decimal**: Aceita tanto o ponto `.` como a vírgula `,`.
- **Operadores Aritméticos**: `+`, `-`, `*`, `/`.
- **Execução**: Teclada `Enter` ou `=`.
- **Limpar Tudo (AC)**: Tecla `Escape`.
- **Seleção de Base**: Clique nas Checkboxes para bloquear ou desbloquear gamas numéricas.

---

## 🛠 Arquitetura do Projeto (Unidades)

O motor está modularizado em várias unidades Object Pascal de alta performance:
- `sMath.pas`: Aritmética Decimal de precisão arbitrária baseada em strings.
- `sHexMath.pas`: Lógica especializada para Base-16.
- `sAlfaMath.pas`: Implementações completas para Base-36.
- `sSwapMath / sHexSwapMath / sAlfaSwapMath`: Gestão de overflow via disco utilizando `TFileStream`.
- `uMainAlfa.pas`: Lógica visual, capturas de teclado e gestão de estado sincronizado da UI.

---

## �️ Estabilidade e Segurança
1. **Bloqueio de Escala**: Assim que um operador é selecionado, a base numérica é bloqueada para evitar erros lógicos durante a conta.
2. **Proteção de Carateres Inválidos**: A interface desativa botões e ignora teclas que não pertencem à base ativa (ex: escrever 'Z' no modo Decimal).
3. **Controlo de Separador Único**: Impede erros de sintaxe ao bloquear a inserção de múltiplos pontos decimais.

---

## 📦 Como Compilar

1. Descarregue o **Lazarus IDE** (versão 3.0 ou superior).
2. Garanta que tem a estrutura de pastas do projeto intacta.
3. Abra o ficheiro `AlfaCalc.lpi`.
4. Pressione `F9` (Compilar e Correr).

---
*KISS - Keep It Simple and Stable.*  
Projeto mantido para o repositório **RCPC**.  
Copyright © 2026 **JTR Software**.
