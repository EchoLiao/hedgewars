/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#ifndef PAGE_ROOMLIST_H
#define PAGE_ROOMLIST_H

#include "AbstractPage.h"

class HWChatWidget;
class AmmoSchemeModel;
class QTableView;
class RoomsListModel;
class QSortFilterProxyModel;

class PageRoomsList : public AbstractPage
{
        Q_OBJECT

    public:
        PageRoomsList(QWidget* parent, QSettings * config);
        void displayError(const QString & message);
        void displayNotice(const QString & message);
        void displayWarning(const QString & message);

        QLineEdit * roomName;
        QLineEdit * searchText;
        QTableView * roomsList;
        QPushButton * BtnCreate;
        QPushButton * BtnJoin;
        QPushButton * BtnRefresh;
        QPushButton * BtnAdmin;
        QPushButton * BtnClear;
        QComboBox * CBState;
        QComboBox * CBRules;
        QComboBox * CBWeapons;
        HWChatWidget * chatWidget;
        QLabel * lblCount;

        void setModel(RoomsListModel * model);

    public slots:
        void setAdmin(bool);
        void setUser(const QString & nickname);
        void updateNickCounter(int cnt);

    signals:
        void askForCreateRoom(const QString &);
        void askForJoinRoom(const QString &);
        void askForRoomList();
        void askJoinConfirmation(const QString &);

    protected:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();

    private slots:
        void onCreateClick();
        void onJoinClick();
        void onRefreshClick();
        void onClearClick();
        void onJoinConfirmation(const QString &);
        void onSortIndicatorChanged(int logicalIndex, Qt::SortOrder order);
        void onFilterChanged();

    private:
        QSettings * m_gameSettings;
        QSortFilterProxyModel * roomsModel;
        QSortFilterProxyModel * stateFilteredModel;
        QSortFilterProxyModel * schemeFilteredModel;
        QSortFilterProxyModel * weaponsFilteredModel;

        AmmoSchemeModel * ammoSchemeModel;

};

#endif
