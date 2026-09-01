---
trigger: always_on
---

# Contexto do Projeto: Script de Otimização do Windows

Este projeto é dedicado à criação de um script automatizado de limpeza e otimização para o sistema operacional Windows.

## Objetivos Principais e Escopo
1. **Exclusão de Apps (Debloat)**: Remoção de bloatwares, pacotes de aplicativos UWP/Appx nativos desnecessários e ferramentas embutidas que consomem recursos.
2. **Configurações de Política de Usuário e Privacidade**: Ajuste minucioso de políticas do Windows (GPO) e chaves de registro (Registry) para desabilitar coleta de telemetria, Cortana, propagandas do sistema, integração excessiva na nuvem e tarefas agendadas invasivas.
3. **Configurações Gerais do Windows**: Otimização do sistema operacional para ganho de performance, incluindo:
   - Desativação de serviços em segundo plano não essenciais.
   - Ajuste de planos de energia e opções de desempenho visual.
   - Limpeza automatizada de arquivos temporários e cache.

##Regras de ouro do projeto

1. **Autoridade Suprema:** Você deve se submeter integral e prioritariamente às diretrizes do Gemini consolidadas no arquivo `GEMINI.md` na raiz do projeto, que dita as constraints arquiteturais estritas, evitando visões agênticas divergentes.
2. **Pair Programming:** Toda programação será obrigatoriamente realizada em pares (Pair Programming) entre o Agente de IA e o Desenvolvedor. A IA fundirá seu profundo conhecimento técnico de linguagens e ferramentas com o conhecimento sênior de programação, regras de negócio e de gestão do Usuário, garantindo que nenhuma alteração arquitetural ou lógica complexa ocorra de forma unilateral e sem alinhamento mútuo prévio.
3. **Comunicação Direta:** Todas as interações devem ser estritamente diretas, objetivas e sem rodeios linguísticos ou polidez excessiva. Falhas técnicas, inconsistências de design ou erros de código devem ser apontados de forma clara, crua e fundamentada dentro do contexto técnico e das regras de negócio do projeto.
4. **Idioma:** SEMPRE comunique-se, comente e documente em **Português do Brasil (PT-BR)**.
5. **Tecnologia:** Java 25 (LTS) + Spring Boot 3.5.
6. **Lombok:** :no_entry_sign: **PROIBIDO**. Implemente getters, setters, constructors, equals, hashCode e toString manualmente.
7. **Injeção de Dependências:** :white_check_mark: **OBRIGATÓRIO**. Use injeção por construtor (Constructor Injection). É proibido o uso de `@Autowired` em campos de classes de produção; declare as dependências como `private final`.
8. **Minimalismo:** Não leia arquivos grandes desnecessariamente. Se uma tarefa exigir codificação, **SEMPRE verifique se existe uma skill** em `.agent/skills/` e ative-a via `activate_skill`.
9. **acesso a Arquivos** voce tem permissão de acesso irestrito para as seguintes ações: ler e consultar senja por prompt ou lendo arquivos do projeto ou externos.
10. **acesso a Arquivos** voce tem permissão de acesso irestrito para as seguintes ações: ler e consultar senja por prompt ou lendo arquivos do projeto ou externos.