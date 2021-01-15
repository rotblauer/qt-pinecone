#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuick/QQuickView>

int main(int argc, char *argv[])
{
    QGuiApplication application(argc, argv);
    application.setOrganizationName("Rotblauer");
    application.setOrganizationDomain("https://github.com/rotblauer");
    application.setApplicationName("PineCone");

    const QString mainQmlApp = QStringLiteral("qrc:///main.qml");
    QQuickView view;
    view.setSource(QUrl(mainQmlApp));
    view.setResizeMode(QQuickView::SizeRootObjectToView);

    // Qt.quit() called in embedded .qml by default only emits
    // quit() signal, so do this (optionally use Qt.exit()).
    QObject::connect(view.engine(), SIGNAL(quit()), qApp, SLOT(quit()));

//    view.setGeometry(QRect(1900, 100, 800, 1500));
//    view.setMinimumSize(QSize(800, 1500));
    view.setMinimumSize(QSize(200, 500));


    view.show();
    return application.exec();
}
