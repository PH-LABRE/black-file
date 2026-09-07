# BLACK FILE: ANOMALY PROTOCOL

Base 3D real em Godot 4 para a campanha single-player offline.

## Estado desta entrega

Esta é a primeira fundação jogável da versão Godot:

- cena 3D real com iluminação, neblina e materiais estilizados;
- câmera em terceira pessoa;
- personagem inspirado no Agent Zero;
- movimentação WASD e corrida com Shift;
- AK-47, pistola e faca;
- troca de armas com 1, 2 e 3;
- disparo por clique esquerdo;
- recarga com R;
- habilidade BLACKOUT com Q;
- inimigos da ECLIPSE e comandante do Capítulo 1;
- combate, vida, munição e objetivo;
- porta de extração e conclusão de episódio;
- save automático em `user://black_file_save.json`;
- briefing e tela de missão fracassada;
- alvo configurado para o renderizador Compatibility, adequado para Web export.

Os modelos e animações nesta fase são procedurais e estilizados, para manter o projeto leve e offline. Eles serão substituídos gradualmente por assets 3D finais.

## Como abrir

1. Instale o Godot 4.x.
2. Abra o Godot Project Manager.
3. Selecione **Import**.
4. Escolha este diretório, contendo `project.godot`.
5. Pressione F6/F5 para executar.

O Godot não estava instalado neste ambiente, então a validação final precisa ser feita no editor Godot local.

## Como exportar para navegador

No Godot:

1. Vá em **Project > Export**.
2. Adicione o preset **Web**.
3. Exporte como `black-file.html`.
4. Para executar localmente, use um servidor HTTP na pasta exportada, por exemplo:

```text
python -m http.server 8000
```

Depois abra `http://localhost:8000/black-file.html`.

A exportação não precisa de internet; o servidor local existe apenas porque navegadores normalmente bloqueiam alguns recursos WebAssembly quando um HTML é aberto diretamente por `file://`.

## Controles

- WASD: movimentar
- Shift: correr
- Mouse: mirar
- Clique esquerdo: atirar/atacar
- 1, 2, 3: trocar arma
- R: recarregar
- Q: habilidade
- E: interagir com a extração
- Esc: pausar

## Próximas camadas da versão completa

1. Menu principal e seleção de personagens.
2. Sistema de 40 episódios e campanhas paralelas.
3. Companheiro Marcus controlado por IA.
4. Cobertura, furtividade, veículos e perseguições.
5. Chefes com fases e cutscenes.
6. Animações e modelos 3D finais.
7. Áudio, diálogos, trilha e exportação Web testada.
