#include <QtGui/QGuiApplication>
#include <src/game/game.h>
#include <src/percolation/percolationsystem.h>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    qmlRegisterType<PercolationSystem>("com.dragly.perc", 1, 0, "PercolationSystem");

    Game game;

    game.start();

    return app.exec();
}
