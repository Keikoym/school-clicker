# Teste de gameplay

## Sprites dos itens

Dez artes em `assets/itens/` foram integradas à mesa, loja e biblioteca. `--script tests/test_sprites.gd` validou os dez PNGs com transparência e gerou `sprites_catalogo.png`. O carregamento direto de PNG nesse teste é intencional para inspecionar os arquivos fonte; o jogo usa recursos importados.

Após a integração, `test_mesa.gd` passou nas 13 condições e `test_colecao.gd` passou nas 25 verificações. As capturas da mesa, estojo aberto e biblioteca foram inspecionadas. Os diagnósticos já conhecidos de shaders, certificados e textura no encerramento continuam presentes; não houve falhas nas verificações de comportamento.

## Mesa, vidas e janela do estojo

`--script tests/test_mesa.gd` verifica 13 condições: decoração antes/depois de compras, QI no rodapé, clique real no X, independência do volume, reabertura pelo estojo, indicadores de vidas nas duas provas e restauração dos itens ao carregar. Para converter corretamente as coordenadas dos controles em eventos de mouse, aplica a transformação final do viewport.

Executado com renderização OpenGL após a troca pelo fundo em primeira pessoa: 13 condições passaram. A suíte de gameplay foi repetida: 23 verificações passaram. As capturas `mesa_completa.png`, `estojo_aberto.png` e `prova1_vidas3.png`/`prova2_vidas1.png` foram inspecionadas. Persistem os diagnósticos de ambiente/encerramento já registrados na revisão anterior.

## Suíte atual após a expansão e revisão

Executar também com os mesmos argumentos `--path . --log-file`:

- `--script tests/auditar_scripts.gd`: carrega os 19 scripts de produção.
- `--script tests/test_colecao.gd`: 25 verificações de coleção, compatibilidade e Português; no modo gráfico produz imagens das quatro abas e da prova.
- `--script tests/test_revisao.gd`: 11 verificações com as funções reais de save/load em `tests/progresso-teste.json`, proteção de arquivos inválidos e bloqueios de prova.

Resultado final da revisão: 59 verificações de comportamento passaram. Consulte `docs/REVISAO.md` para limitações e diagnósticos pendentes. O resultado histórico abaixo é anterior à expansão.

Executar na raiz do projeto com Godot 4.7.1:

```text
Godot.exe --headless --path . --log-file ./tests/gameplay.log --script tests/test_gameplay.gd
```

Para conferir a renderização, retirar `--headless` e adicionar `--rendering-method gl_compatibility --audio-driver Dummy --windowed --resolution 1280x720`. A execução salva `tests/loja.png` antes de fechar a loja.

O teste instancia a cena real com uma subclasse de Main que desativa leitura e gravação do save pessoal. Compras usam os sinais dos botões; Esc usa o sistema de entrada. Resultados de minigames e tempo esgotado são simulados pelos callbacks das provas. A restauração do progresso é verificada em memória, sem testar persistência em disco.

## Resultado em 21/09/2026

23 verificações passaram, tanto sem janela quanto com renderização OpenGL. A imagem da loja foi inspecionada: textos e botões estão visíveis, incluindo a instrução de Esc.

Cobertura: clique, quatro compras, custos, atualização de dicas, produção e arredondamento, transições rápidas da loja, Esc, hover independente, restauração em memória, bloqueio inicial da Prova 2, pausa de QI durante prova, vidas e timer inicial, vitória da Prova 1 e nova tentativa após tempo esgotado na Prova 2.

Limitações: áudio audível, gameplay completo dos quizzes e save em disco não foram validados. O ambiente emitiu erros de acesso à pasta `user://` e ao repositório de certificados; também houve avisos de recursos/textura ainda alocados ao encerrar. As verificações de comportamento terminaram com código 0; esses diagnósticos não estão resolvidos por esta suíte.
