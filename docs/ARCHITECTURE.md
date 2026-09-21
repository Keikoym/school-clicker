# Arquitetura — notas de manutenção

O projeto usa Godot e GDScript. `principalgame.tscn` contém o gameplay e `main.gd` coordena QI, loja, progresso, áudio e provas. Os scripts `botao_*.gd` mantêm as regras de compra e os custos.

## Usabilidade da loja — 21/09/2026

- `main.gd::_descricao_melhoria` calcula a prévia de cada compra, usando as fórmulas e o arredondamento das recompensas atuais. Ao mudar as regras nos scripts de compra, atualizar também essas prévias.
- As dicas exibem o resultado antes/depois e quanto QI falta. O corretivo informa quando ainda falta um gerador.
- Os sinais de melhoria de clique e multiplicador atualizam a interface após aplicar o novo valor.
- Uma única referência `tween_loja` controla abertura/fechamento; uma nova transição cancela a anterior. Iniciar uma prova também cancela a animação da loja.
- Esc fecha a loja via `_unhandled_key_input`, sem sair de provas.
- Clique e loja têm animações de hover independentes. O pulinho e o hover do botão de clique cancelam um ao outro para evitar disputa pela escala.
- Textos flutuantes ignoram eventos do mouse.

Custos, recompensas, formato do save e desbloqueios permanecem os mesmos.

## Expansão da coleção — 21/09/2026

`colecao.gd` é um CanvasLayer criado por Main antes de carregar o save. Mantém o catálogo, compras únicas, contagem de cliques, conquistas e interface da mochila. Reaproveita `BotaoUpgrade3` como acesso e tem tratamento de Esc anterior ao da loja. A interface usa containers e rolagem para caber na resolução base 640×360.

`main.gd::obter_ganho_clique` e `obter_producao_passiva` somam os bônus da coleção após calcular os valores originais. As prévias da loja incluem esses bônus. Os valores básicos dos upgrades permanecem separados para evitar que uma compra original apague os colecionáveis.

O save recebe o campo opcional `colecao`, contendo IDs adquiridos, IDs das conquistas e cliques. Saves antigos inicializam a coleção vazia. Bônus são recalculados a partir dos IDs conhecidos, nunca acumulados ao carregar. Conquistas antigas já alcançadas por provas são reconhecidas a partir do estado carregado.

O Seminário 2 mantém a cena e o controlador existentes. `minigames_quiz_2.gd` contém as 20 questões; a derrota informa a resposta correta e `prova_2.gd` aguarda 1,8 segundo para permitir leitura. A aprovação exige cinco acertos, inclusive se o banco vier a se esgotar.

## Revisão de segurança do progresso e regressões

O save é gravado em `.tmp`, verificado e renomeado sobre o arquivo final. `salvamento_bloqueado` impede autosave e gravação ao fechar quando o carregamento detecta arquivo ilegível, JSON inválido ou versão futura. `_obter_caminho_save()` permite aos testes exercitar as funções reais em um arquivo separado.

O início das provas verifica estado ativo, conclusão e pré-requisito da Prova 2. Os seis botões de compra originais também bloqueiam operações durante provas. Avisos de conquistas aguardam fora da mochila e das provas, e seu tempo de exibição só avança quando visíveis. Os dois nós `Timer_Quiz`, não usados pelos scripts, foram removidos; timers gerais e barras visuais continuam ativos.

Os scripts legados `node_2d.gd` e `botao_voltar.gd` não estão ligados às cenas atuais. O primeiro foi corrigido para declarar suas referências de áudio. A propriedade `subindo` é mantida apenas por compatibilidade do save, conforme comentário existente. Testes, documentação e logs foram excluídos do preset de exportação.

## Mesa e vidas

- `assets/backgrounds/mesa_primeira_pessoa.png` substitui a foto frontal por uma vista do aluno sentado. O original foi preservado e o prompt está ao lado do novo arquivo.
- O contador de QI fica no rodapé. Objetos antigos foram reposicionados; `itens_mesa.gd` desenha livros, caderno, luminária e lápis extras quando seus IDs estão adquiridos. O desenho acompanha compras e carregamento, sem alterar bônus.
- `vidas_prova.gd` desenha três corações e o número de vidas, com breve destaque ao perder uma. Os dois controladores atualizam o mesmo componente; vidas e tempos não mudaram.
- Main transfere `JanelaLoja` para `CamadaLoja` em `_ready`. O CanvasLayer 5 e seu fundo bloqueiam os cliques no volume e no gameplay atrás da loja. A mochila permanece na camada 10. A janela já não herda escala/posição do botão do estojo. Sinais conectados na cena são preservados pelo reparent.
- Avisos de conquista ficam acima da mesa para deixar o contador inferior livre.

## Sprites finais dos itens

`assets/itens/` contém dez PNGs: três livros, caderno de resumos, estojo completo, luminária, lápis, apontador, marca-texto e corretivo. Os prompts e o método de geração estão em `assets/itens/PROMPTS.md`.

`itens_mesa.gd::SPRITES` centraliza as seis texturas da coleção. `colecao.gd` usa essas mesmas imagens nas miniaturas, substituindo cartões com iniciais. A mesa desenha os livros, caderno e luminária com sprites, no lugar de primitivas geométricas. O estojo é representado pelo botão de acesso à loja, que ganha sua cor plena quando o item é adquirido.

Os quatro upgrades originais receberam os mesmos sprites em seus ícones e objetos de mesa. `LapisMesa` aparece após melhorar o clique e segue o estado salvo. A sequência de texturas do caderno principal foi preservada para manter a progressão visual existente. Custos, bônus, provas e formato do save não foram alterados nesta etapa.


## Desenvolvedor e notas de atualização

painel_desenvolvedor.gd cria a interface no menu e gameplay. main.gd bloqueia todas as gravações durante debug. O snapshot em memória é restaurado em uma cena nova ao encerrar, incluindo botões removidos e progresso ainda não salvo. Fechar o aplicativo no debug descarta a sessão temporária. As ferramentas não abrem durante provas ou mochila.

APÓS ATUALIZAR, inserir as mudanças no início de notas_atualizacao.gd (data, título e mudanças). Essa é a fonte das notas exibidas no jogo e acompanha a exportação.
