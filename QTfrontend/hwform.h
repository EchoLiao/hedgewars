/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005-2007 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef HWFORM_H
#define HWFORM_H

#include <QMainWindow>
#include <QStack>
#include <QTime>

#include "netserver.h"
#include "game.h"
#include "ui_hwform.h"

class HWGame;
class HWTeam;
class HWNewNet;
class GameUIConfig;
class HWNetRegisterServer;
class QCloseEvent;

class HWForm : public QMainWindow
{
	Q_OBJECT

public:
	HWForm(QWidget *parent = 0);
	Ui_HWForm ui;

private slots:
	void GoToMain();
	void GoToSinglePlayer();
	void GoToSetup();
	void GoToMultiplayer();
	void GoToSaves();
	void GoToDemos();
	void GoToNet();
	void GoToInfo();
	void GoToSimpleGame();
	void GoToTraining();
	void GoToSelectWeapon();
	void GoToSelectNewWeapon();
	void GoToNetServer();
	void GoToPage(quint8 id);
	void GoBack();
	void btnExitPressed();
	void btnExitClicked();
	void IntermediateSetup();
	void NewTeam();
	void EditTeam();
	void TeamSave();
	void TeamDiscard();
	void SimpleGame();
	void PlayDemo();
	void StartTraining();
	void NetConnect();
	void NetConnectServer(const QString & host, quint16 port);
	void NetStartServer();
	void NetDisconnect();
	void NetGameEnter();
	void NetStartGame();
	void AddNetTeam(const HWTeam& team);
	void StartMPGame();
	void GameStateChanged(GameState gameState);
	void GameStats(char type, const QString & info);
	void ForcedDisconnect();
	void ShowErrorMessage(const QString &);
	void GetRecord(bool isDemo, const QByteArray & record);
	void CreateNetGame();
	void UpdateWeapons();

private:
	void _NetConnect(const QString & hostName, quint16 port, const QString & nick);
	void UpdateTeamsLists(const QStringList* editable_teams=0);
	void CreateGame(GameCFGWidget * gamecfg, TeamSelWidget* pTeamSelWidget, QString ammo);
	void closeEvent(QCloseEvent *event);
	enum PageIDs {
		ID_PAGE_SIMPLEGAME      =  0,
		ID_PAGE_SETUP_TEAM      =  1,
		ID_PAGE_SETUP           =  2,
		ID_PAGE_MULTIPLAYER     =  3,
		ID_PAGE_DEMOS           =  4,
		ID_PAGE_NET             =  5,
		ID_PAGE_NETCFG          =  6,
		ID_PAGE_INFO            =  7,
		ID_PAGE_MAIN            =  8,
		ID_PAGE_GAMESTATS       =  9,
		ID_PAGE_SINGLEPLAYER    = 10,
		ID_PAGE_TRAINING        = 11,
		ID_PAGE_SELECTWEAPON    = 12,
		ID_PAGE_NETSERVER       = 13,
		ID_PAGE_INGAME          = 14
		};
	HWGame * game;
	HWTeam * editedTeam;
	HWNewNet * hwnet;
	GameUIConfig * config;
	QStack<quint8> PagesStack;
	HWNetServer* pnetserver;
	HWNetRegisterServer* pRegisterServer;
	QTime eggTimer;
	void AddStatText(const QString & msg);
	void OnPageShown(quint8 id, quint8 lastid=0);
};

#endif
