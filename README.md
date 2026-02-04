# Desafio EveryDrive (Salesforce)

Este repositório contém a implementação do desafio (Apex, LWC, Flow) no formato SFDX.

## Evidências / PDF
- O arquivo único para montar o PDF de entrega está em: `Evidencias_Desafio.md`.
- As imagens/prints ficam em: `evidencias/`.

## Estrutura (SFDX)
- Código fonte: `force-app/main/default/`
- Scripts Apex: `scripts/apex/`
- Resultados de testes: `test-results/`

## Testes (SF CLI)
Rodar testes do desafio com coverage:

```bash
sf apex run test --target-org everydrive --class-names EveryDriveCustomerTierControllerTest --class-names AccountCustomerTierNotifierTest --class-names RentalTriggerHandlerTest --result-format human --wait 60 --code-coverage
```

Validate (check-only) do source do desafio:

```bash
sf project deploy validate --target-org everydrive --source-dir force-app --test-level RunSpecifiedTests --tests EveryDriveCustomerTierControllerTest --tests AccountCustomerTierNotifierTest --tests RentalTriggerHandlerTest --wait 60
```

## Planejamento (conteúdo para o slide)

### Estratégia (ordem de execução)
1) Modelagem (objetos/campos)
2) Flow (automação de tier)
3) UI (LWC + Static Resource)
4) Triggers/Handlers (Rental + Account)
5) Testes, coverage e validate
6) Evidências (prints) + PDF

### Ferramentas usadas
- VS Code + Salesforce Extensions
- `sf` CLI
- Developer Console (Execute Anonymous + Logs)
- Git (controle de versão local) para manter evolução incremental

### Como me organizei (prática)
- Entregas pequenas e incrementais: após cada etapa (Flow, Apex, LWC), validei no org com um cenário simples.
- Testes junto com a implementação: sempre que criei/ajustei regra em Apex/trigger, adicionei teste cobrindo o cenário.
- Validação contínua: rodei `sf apex run test --code-coverage` para confirmar cobertura e usei `deploy validate` para simular a entrega.
- Evidências em paralelo: conforme cada funcionalidade ficava pronta, já separava os prints sugeridos no checklist.

### Cronograma (exemplo, 3 dias)
- Dia 1 (base): modelagem de dados + Flow + primeiro ciclo de validação no org
- Dia 2 (feature): Apex (controller/handlers) + LWC + publicação na página + debug via Execute Anonymous
- Dia 3 (qualidade/entrega): testes (cobertura e cenários), `deploy validate`, coleta final de evidências e montagem do PDF
