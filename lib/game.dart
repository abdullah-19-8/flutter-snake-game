// game.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snake_game/services/route_service.dart';
import 'package:snake_game/services/user_service.dart';
import 'package:snake_game/utils/bot.dart';
import 'package:snake_game/utils/dialogs.dart';

import 'model/board.dart';
import 'model/snake.dart';
import 'model/user.dart';

class Game extends StatefulWidget {
  final User user;
  const Game(this.user, {super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  static int numberOfSquares = 640;
  static int foodRange = numberOfSquares - 50;
  static int botRange = numberOfSquares - 50;
  // Initialize snake with positions, name, color and score of 0
  late Snake snake;
  late Board board;
  ////////////
  late Timer timer;

  List<Snake> bots = [];
  List<Snake> placeHolderBots = [];
  List<String> directions = ["up", "down", "left", "right"];

  int? food;
  int? coin;
  static var random;
  static var randomCoin;

  late String currentPosition;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  startGame() {
    // Reset any active bots
    resetBots();
    // Initialize the snake and board
    initializeModels();
    // Initialize any random vars
    initializeRandoms();
    // Initialize the food and coin items
    initializeItems();
    // start the game loop
    initializeGameLoop();
    // Game loop
  }

  resetBots() {
    placeHolderBots = [];
    bots = [];
  }

  initializeModels() {
    board = Board(
      id: "default",
      color: Colors.black,
      name: "default",
      price: 0,
    );

    Random rand = Random();
    final direction = rand.nextInt(3);
    final position = rand.nextInt(botRange);

    snake = Snake(
      name: "default",
      color: Colors.orange,
      direction: directions[direction],
      coins: 0,
      diamonds: 0,
      price: 0,
      score: 0,
      positions: generateRandomPositionList(directions[direction], position, 5),
    );
  }

  initializeRandoms() {
    random = Random();
    randomCoin = Random();
  }

  initializeItems() {
    food = random.nextInt(foodRange);
    coin = randomCoin.nextInt(foodRange);
  }

  initializeGameLoop() {
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      updateGame();
      if (gameOver()) {
        finishGame(context);
      }
    });
  }

  gameOver() {
    for (var i = 0; i < snake.positions.length; i++) {
      var count = 0;
      for (var j = 0; j < snake.positions.length; j++) {
        for (var x = 0; x < bots.length; x++) {
          for (var t = 0; t < bots[x].positions.length; t++) {
            if (snake.positions[i] == bots[x].positions[t]) {
              count = 2;
            }
          }
        }
        if (snake.positions[i] == snake.positions[j]) {
          count += 1;
        }
        if (count == 2) {
          return true;
        }
      }
    }
    return false;
  }

  finishGame(context) async {
    final routeService = Provider.of<RouteService>(context, listen: false);
    timer.cancel();
    await saveProgress();
    removeBots();
    showGameOverDialog(
      context,
      snake,
      () {
        restartGame();
        Navigator.pop(context);
      },
      () {
        Navigator.pop(context);
        routeService.navigate(0);
      },
    );
  }

  saveProgress() async {
    final userService = Provider.of<UserService>(context, listen: false);
    await userService.updatePreferences(snake);
  }

  removeBots() {
    setState(() {
      for (var x = 0; x < bots.length; x++) {
        bots.remove(bots[x]);
      }
    });
  }

  restartGame() {
    startGame();
  }

  updateGame() {
    setState(() {
      checkToSpawnBot();
      if (bots.isNotEmpty) {
        moveBots();
      }
      moveSnake();
      detectCollision();
    });
  }

  moveBots() {
    for (var i in bots) {
      switch (i.direction) {
        case "down":
          if (i.positions.last > numberOfSquares - 20) {
            i.positions.add(i.positions.last + 20 - numberOfSquares);
          } else {
            i.positions.add(i.positions.last + 20);
          }
          break;
        case "up":
          if (i.positions.last < 20) {
            i.positions.add(i.positions.last - 20 + numberOfSquares);
          } else {
            i.positions.add(i.positions.last - 20);
          }
          break;
        case "left":
          if (i.positions.last % 20 == 0) {
            i.positions.add(i.positions.last - 1 + 20);
          } else {
            i.positions.add(i.positions.last - 1);
          }
          break;
        case "right":
          if ((i.positions.last + 1) % 20 == 0) {
            i.positions.add(i.positions.last + 1 - 20);
          } else {
            i.positions.add(i.positions.last + 1);
          }
          break;
        default:
      }
      i.positions.removeAt(0);
    }
  }

  checkToSpawnBot() {
    if (snake.score >= 20 && bots.isEmpty && placeHolderBots.isEmpty) {
      spawnBots();
    }
    if (snake.score >= 50 && bots.length == 1 && placeHolderBots.isEmpty) {
      spawnBots();
    }
  }

  spawnBots() {
    var direction = random.nextInt(3);
    var position = random.nextInt(botRange);
    var positions = generateRandomPositionList(
      directions[direction],
      position,
      5,
    );
    Snake bot1 = Snake(
      name: "bot 1",
      color: Colors.red,
      direction: directions[direction],
      score: 0,
      positions: positions,
    );
    setState(() {
      placeHolderBots.add(bot1);
    });
    Future.delayed(
      const Duration(seconds: 3),
      () => setState(() {
        placeHolderBots.remove(bot1);
        bots.add(bot1);
      }),
    );
  }

  moveSnake() {
    switch (snake.direction) {
      case "down":
        // LAST ROW OF GRIDS
        if (snake.positions.last > numberOfSquares - 20) {
          snake.positions.add(snake.positions.last + 20 - numberOfSquares);
        } else {
          snake.positions.add(snake.positions.last + 20);
        }
        break;
      case "up":
        if (snake.positions.last < 20) {
          snake.positions.add(snake.positions.last - 20 + numberOfSquares);
        } else {
          snake.positions.add(snake.positions.last - 20);
        }
        break;
      case "left":
        if (snake.positions.last % 20 == 0) {
          snake.positions.add(snake.positions.last - 1 + 20);
        } else {
          snake.positions.add(snake.positions.last - 1);
        }
        break;
      case "right":
        if ((snake.positions.last + 1) % 20 == 0) {
          snake.positions.add(snake.positions.last + 1 - 20);
        } else {
          snake.positions.add(snake.positions.last + 1);
        }
        break;
      default:
    }
  }

  detectCollision() {
    if (snake.positions.last == coin) {
      snake.coins += 50;
      coin = randomCoin.nextInt(foodRange);
    } else if (snake.positions.last == food) {
      snake.score += 20;
      food = random.nextInt(foodRange);
    } else {
      snake.positions.removeAt(0);
    }
  }

  /// It takes a direction, an initial position and a snake length and returns a list of positions that
  /// the snake will occupy
  ///
  /// Args:
  ///   direction (String): The direction in which the snake is moving.
  ///   initialPosition (int): The initial position of the snake's head.
  ///   snakeLength (int): The length of the snake.
  ///
  /// Returns:
  ///   A list of integers.
  generateRandomPositionList(
    String direction,
    int initialPosition,
    int snakeLength,
  ) {
    List<int> positionsList = [];
    positionsList.add(initialPosition);
    for (var i = 0; i < snakeLength - 1; i++) {
      switch (direction) {
        case "down":
          if (positionsList.last > numberOfSquares - 20) {
            positionsList.add(positionsList.last + 20 - numberOfSquares);
          } else {
            positionsList.add(positionsList.last + 20);
          }
          break;
        case "up":
          if (positionsList.last < 20) {
            positionsList.add(positionsList.last - 20 + numberOfSquares);
          } else {
            positionsList.add(positionsList.last - 20);
          }
          break;
        case "left":
          if (positionsList.last % 20 == 0) {
            positionsList.add(positionsList.last - 1 + 20);
          } else {
            positionsList.add(positionsList.last - 1);
          }
          break;
        case "right":
          if ((positionsList.last + 1) % 20 == 0) {
            positionsList.add(positionsList.last + 1 - 20);
          } else {
            positionsList.add(positionsList.last + 1);
          }
          break;
        default:
      }
    }
    return positionsList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onVerticalDragUpdate: (details) {
                if (snake.direction != "up" && details.delta.dy > 0) {
                  snake.direction = "down";
                } else if (snake.direction != "down" && details.delta.dy < 0) {
                  snake.direction = "up";
                }
              },
              onHorizontalDragUpdate: (details) {
                if (snake.direction != "left" && details.delta.dx > 0) {
                  snake.direction = "right";
                } else if (snake.direction != "right" && details.delta.dx < 0) {
                  snake.direction = "left";
                }
              },
              child: GridView.builder(
                itemCount: numberOfSquares,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 20,
                ),
                itemBuilder: (context, index) {
                  if (snake.positions.contains(index)) {
                    return snakePart();
                  } else if (food == index) {
                    return foodPart();
                  } else if (coin == index) {
                    return coinPart();
                  } else {
                    for (var i = 0; i < bots.length; i++) {
                      if (bots[i].positions.contains(index)) {
                        return botPart();
                      }
                    }
                    for (var i = 0; i < placeHolderBots.length; i++) {
                      if (placeHolderBots[i].positions.contains(index)) {
                        // ignore: prefer_const_constructors
                        return PlaceHolderBot();
                      }
                    }
                  }
                  return boardSquare();
                },
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[_scoreWidget(), _coinsWidget()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget boardSquare() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget snakePart() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget botPart() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget foodPart() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget coinPart() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.yellow,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Image.asset("assets/img/singlecoin.png"),
      ),
    );
  }

  Widget _scoreWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Score: ",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 25,
          ),
        ),
        Text(
          snake.score.toString(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 25,
          ),
        ),
      ],
    );
  }

  Widget _coinsWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset("assets/img/singlecoin.png", width: 25),
        const SizedBox(width: 5),
        Text(
          snake.coins.toString(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 25,
          ),
        ),
      ],
    );
  }
}
