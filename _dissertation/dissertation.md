---
title: Solidifying Modern SMT Solvers
notitle: false 

description: |
    Satisfiability Modulo Theory (SMT) solvers are among the most powerful and mature formal methods. They are foundational in software research and industry—for example, AWS uses them to verify cloud services. SMT solvers solve NP-hard problems and build trust through proof, making correctness and performance crucial, especially in safety- and security-critical domains. Though long trusted, SMT solvers' reliability had not been thoroughly tested. This thesis challenges that trust through five approaches to improve solver correctness and performance  The first, Semantic Fusion, validates SMT solver correctness and revealed dozens of soundness bugs in Z3 and CVC4. Next, Type-Aware Operator Mutation, a simple but highly effective method, uncovered 1,254 bugs, including soundness bugs across nearly all theories. To improve upon this, Generative Type-Aware Mutation found 322 more bugs, including long-standing ones in CVC4. Janus targets incompleteness bugs, while Grammar-based Enumeration (ET) tackles correctness and performance. ET also helps track SMT solver evolution. Across five years, we found 1,825 unique bugs (483 soundness), with 1,333 fixed. This thesis has advanced the hardening of formal methods.

layout: project
logo_url: "https://www.research-collection.ethz.ch/handle/20.500.11850/725868"
image: "img/thesis-cover.png"
last-updated: 2017-04-11
---
