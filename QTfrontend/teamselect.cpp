#include <QLabel>
#include <QPixmap>
#include <QPushButton>
#include <QFrame>
#include <QDebug>

#include <vertScrollArea.h>
#include "teamselect.h"
#include "teamselhelper.h"
#include "frameTeam.h"

void TeamSelWidget::addTeam(HWTeam team)
{
  frameDontPlaying->addTeam(team);
  curDontPlayingTeams.push_back(team);
  QObject::connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
		   this, SLOT(changeTeamStatus(HWTeam)));
}

//void TeamSelWidget::removeTeam(__attribute__ ((unused)) HWTeam team)
//{
  //curDontPlayingTeams.erase(std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team));
//}

void TeamSelWidget::changeTeamStatus(HWTeam team)
{
  list<HWTeam>::iterator itDontPlay=std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team);
  list<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);

  if(itDontPlay==curDontPlayingTeams.end()) {
    // playing team => dont playing
    curDontPlayingTeams.push_back(*itPlay);
    curPlayingTeams.erase(itPlay);
  } else {
    // dont playing team => playing
    curPlayingTeams.push_back(*itDontPlay);
    curDontPlayingTeams.erase(itDontPlay);
  }

  FrameTeams* pRemoveTeams;
  FrameTeams* pAddTeams;
  if(itDontPlay==curDontPlayingTeams.end()) {
    pRemoveTeams=framePlaying;
    pAddTeams=frameDontPlaying;
  } else {
    pRemoveTeams=frameDontPlaying;
    pAddTeams=framePlaying;
  }

  pAddTeams->addTeam(team);
  pRemoveTeams->removeTeam(team);
  QObject::connect(pAddTeams->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
		   this, SLOT(changeTeamStatus(HWTeam)));
  QSize szh=sizeHint();
  if(szh.isValid()) resize(szh);
  else {
    szh=pAddTeams->sizeHint();
    QSize szh1=pRemoveTeams->sizeHint();
    if(szh.isValid() && szh1.isValid()) {
      pAddTeams->resize(szh);
      pRemoveTeams->resize(szh1);
    }
  }
}

void TeamSelWidget::addScrArea(FrameTeams* pfteams, QColor color)
{
  VertScrArea* area=new VertScrArea(color);
  area->setWidget(pfteams);
  mainLayout.addWidget(area, 30);
}

TeamSelWidget::TeamSelWidget(QWidget* parent) :
  QWidget(parent), mainLayout(this)
{
  framePlaying=new FrameTeams();
  frameDontPlaying=new FrameTeams();
  addScrArea(framePlaying, QColor("DarkTurquoise"));
  addScrArea(frameDontPlaying, QColor("LightGoldenrodYellow"));
}
