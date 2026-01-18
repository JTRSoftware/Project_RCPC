# AlfaCalc

A **AlfaCalc** é uma calculadora de alta performance e precisão arbitrária, desenhada para engenheiros, programadores e entusiastas que necessitam de realizar cálculos complexos em múltiplas bases numéricas (Decimal, Hexadecimal e Alfadecimal/Base-36).

Desenvolvida pela **JTR Software**, a AlfaCalc segue a filosofia: *"É simples parecer complicado, o complicado é parecer simples."*

## 🚀 Funcionalidades Principais

- **Display Multi-Base Sincronizado**: Visualize os seus cálculos simultaneamente em Decimal, Hexadecimal e Alfadecimal (Base-36).
- **Sistema Infinity Display**: Interface robusta que suporta scroll e cópia de números de comprimento virtualmente ilimitado sem falhas visuais.
- **Motor de Precisão Arbitrária**: Realize cálculos com números de magnitude extrema, limitados apenas pelo seu hardware.
- **Suporte a Memória Swap**: Aritmética única baseada em disco para operações que excedem a memória RAM disponível.
- **Benchmarking de Alta Precisão**: Medição do tempo de cálculo em tempo real (milissegundos/segundos) para cada operação.
- **Modo Turbo (Conversão Automática)**: Otimize a performance ao lidar com milhões de dígitos, desativando a conversão de base em tempo real.
- **Bloqueios de Segurança**: Gestão inteligente de estado que impede operações inválidas, como mudar de base a meio de um cálculo ou a inserção acidental de múltiplos separadores decimais.
- **Suporte Total de Teclado**: Atalhos ativos para todas as operações, troca de base e introdução numérica.

## 🛠 Stack Tecnológica

- **Lazarus / FreePascal**: Núcleo em Object Pascal de alta eficiência.
- **Unidades Matemáticas Customizadas**: 
  - `sMath.pas`: Lógica decimal de precisão arbitrária.
  - `sHexMath.pas`: Lógica em Base-16.
  - `sAlfaMath.pas`: Lógica em Base-36.
  - `sSwapMath.pas`: Gestão de overflow via disco (Swap).

## 📦 Instalação

Este projeto foi construído utilizando o **Lazarus**. 

1. Clone o repositório.
2. Abra o ficheiro `AlfaCalc.lpi` no IDE Lazarus.
3. Compile e Corra (F9).

## 📜 Licença

Projeto desenvolvido para o repositório RCPC.
Copyright (c) 2026 JTR Software.

---
*KISS - Keep It Simple and Stable.*
