# Revisão — 21/09/2026

## Problemas encontrados e corrigidos

| Prioridade | Problema | Correção |
| --- | --- | --- |
| Alta | Save recusado por corrupção/versão futura podia ser sobrescrito pelo autosave ou ao fechar | Bloqueio de gravação até um carregamento válido |
| Alta | Gravação direta truncava o save antes de concluir a escrita | Arquivo temporário, verificação de escrita e substituição por renomeação |
| Média | Reentrada no início de prova podia reiniciar vidas; chamadas diretas não validavam desbloqueio | Guardas de prova ativa, concluída e pré-requisito |
| Média | Callbacks de compra não verificavam modo prova | Bloqueio nos seis botões originais |
| Média | Título novo de Português ultrapassava a tela | Área do contador ampliada |
| Média | Avisos de conquista cobriam cronômetro e rodapé da mochila | Avisos aguardam o gameplay; tempo de leitura pausa enquanto ocultos |
| Média | Falha na troca de cena deixava uma camada opaca bloqueando o menu/ajuda | Restaurados transparência e passagem de entrada no caminho de erro |
| Média | Script legado `node_2d.gd` usava referências de áudio não declaradas | Referências declaradas com busca segura |
| Baixa | Dois nós `Timer_Quiz` não eram usados | Removidos sem alterar os timers das provas |

## Verificação

- 19 scripts de produção carregados pelo Godot, sem erro de compilação.
- 23 verificações de gameplay original: passaram.
- 25 verificações da coleção e do quiz de Português: passaram.
- 11 verificações de regressão e save/load real em arquivo de teste: passaram.
- Total: 59 verificações de comportamento, sem falhas na rodada final.
- Imagens da mochila e da prova renderizadas em OpenGL e inspecionadas.
- Busca de referências não encontrou variáveis com somente a declaração. Isso é uma triagem textual, não uma prova formal de ausência de código morto. `subindo` foi mantida por compatibilidade com saves.

O teste de Português escolhe as respostas pelos botões, inclui um erro que retira vida e conclui com cinco acertos sem repetir perguntas. O save de produção do jogador não foi lido nem alterado.

## Limites e pendências

- O Godot emitiu diagnósticos de certificados e inicialização de shaders neste ambiente; não houve falha nas verificações de comportamento.
- Ao encerrar imediatamente alguns testes, foram reportados um stream/playback MP3 ainda referenciado e, na execução gráfica, uma textura ainda alocada. A origem completa desses avisos de encerramento permanece pendente; não são contabilizados como resolvidos.
- O teste de arquivo corrompido gera intencionalmente um erro de JSON, identificado no log como cenário esperado.
- Áudio audível e executável exportado não foram validados. Os testes executam o projeto no Godot 4.7.1.
