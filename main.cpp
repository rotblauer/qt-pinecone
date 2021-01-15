#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuick/QQuickView>

int main(int argc, char *argv[])
{
    QGuiApplication application(argc, argv);
    const QString mainQmlApp = QStringLiteral("qrc:///main.qml");
    QQuickView view;
    view.setSource(QUrl(mainQmlApp));
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    // Qt.quit() called in embedded .qml by default only emits
    // quit() signal, so do this (optionally use Qt.exit()).
    QObject::connect(view.engine(), SIGNAL(quit()), qApp, SLOT(quit()));
//    view.setGeometry(QRect(100, 100, 360, 640));
    view.setMinimumSize(QSize(720, 1280));
    view.show();
    return application.exec();
}
