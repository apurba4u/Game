abstract class BaseGameController {
  void startGame();
  void pauseGame();
  void resumeGame();
  void restartGame();
  void endGame();
  Future<void> saveScore();
}
