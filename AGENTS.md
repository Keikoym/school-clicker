# School Clicker

School Clicker é um jogo escolar do tipo clicker feito em Godot 4.7, usando GDScript.

## Mapa rápido

- `project.godot`: configuração do projeto; a cena inicial é `menu_principal.tscn`.
- `menu_principal.tscn`, `CenaDeAjuda.tscn`: menu e ajuda.
- `principalgame.tscn`: gameplay, HUD, loja, objetos da mesa, provas e áudio.
- `main.gd`: QI, clique, produção passiva, progressão visual, loja, save/load e coordenação das provas.
- `prova_1.gd`, `prova_2.gd`: vidas, tempo e sequência das provas.
- `minigames_quiz.tscn`/`.gd` e `minigames_quiz2.tscn`/`minigames_quiz_2.gd`: quizzes atuais.
- Scripts `botao_*.gd`: compras e acesso aos seminários.
- `economia.gd`: preços por nível; `apresentacao.gd`: tema da loja e HUD; `colecao.gd` e `selo_conquista.gd`: mochila e conquistas.

Antes de alterações grandes, consulte `docs/GAME_DESIGN.md`, `docs/ARCHITECTURE.md` e `docs/TODO.md`.

Preserve o loop de QI e clique, save/load, upgrades e custos atuais, loja, progressão visual, objetos da mesa, duas provas com vidas/tempo, música/volume e desbloqueio da Prova 2 após a Prova 1. Antes de criar um sistema novo, procure por uma implementação semelhante nas cenas e scripts existentes. Mudanças importantes devem atualizar o documento correspondente em `docs/`.

Após cada atualização, registrar as mudanças no início de notas_atualizacao.gd, preservando o histórico.
