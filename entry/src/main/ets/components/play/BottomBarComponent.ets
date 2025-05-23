import { Song, Song_INITIAL } from "../../common/entities/Song"
import { pauseMusic, playNext, playPre, playQueue, resumeMusic } from "../../common/functions/play/playControl"
import playQueueUtils from "../../common/utils/play/PlayQueueUtils"
import { PlayQueueButton } from "../buttons/PlayQueueButton"
import { Player } from "../../common/view/Player"
import { StorageConstants } from "../../common/constants/StorageConstants"
import Constants from "../../common/constants/Constants"
import { ClickUtil } from "@pura/harmony-utils"
import { PLAYMODE } from "../../common/model/Enum"
import { lyricsPipManager } from "../../pages/lyrics/PipLyrics"
import { DownloadListSheet } from "../sheets/DownloadListSheet"
import { DownloadItem } from "../../common/model/Download"

/**
 * 底部播控组件
 */
@Component
export struct BottomBarComponent {
  @StorageLink(StorageConstants.IS_PLAYING) isPlaying: boolean = false
  @StorageProp(StorageConstants.PLAY_MODE) playmode: PLAYMODE = PLAYMODE.SINGLE
  @StorageProp(StorageConstants.PLAY_SONG) song: Song = Song_INITIAL
  @StorageProp(StorageConstants.PLAY_ARTISTS) artists: string = ''
  @StorageProp(StorageConstants.IS_PAUSED) isPaused: boolean = true
  @StorageProp(StorageConstants.PIC_URL) picUrl: string = ''
  @StorageProp(StorageConstants.PLAY_TIME) playTime: number = 0
  @StorageProp(StorageConstants.DOWNLOAD_QUEUE) downloadQueue: DownloadItem[] = []
  @StorageProp(StorageConstants.CURRENT_LYRIC) @Watch('updateLyrics') currentLyric: string = ''
  @StorageProp(StorageConstants.MINI_BAR_BLUR) miniBarBlur: boolean = true
  @State isShow: boolean = false
  @State isShowDownload: boolean = false

  private downloadSheetOptions: SheetOptions = {
    preferType: SheetType.CENTER,
    height: '60%',
    dragBar: false,
    showClose: false,
    backgroundColor: $r('app.color.background'),
    onDisappear: (() => { this.isShowDownload = false })
  }

  updateLyrics() {
    lyricsPipManager.updateLyrics(this.currentLyric)
  }

  private handlePlayClick = async () => {
    if(!this.isPlaying) {
      await playQueue(playQueueUtils.currentQueueIndex)
    }
    animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.isShow = true
    })
  }

  build() {
    Column({ space: 5 }) {
      Row() {
        Image($r('app.media.ic_public_cloud_download'))
          .width(Constants.SIZE_ICON_BUTTON_COMMON)
          .fillColor($r('app.color.app_red'))
          .backgroundColor($r('app.color.main'))
          .borderRadius(Constants.RADIUS_FULL)
          .padding(5)
          .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.7 })
          .opacity(0.8)
          .draggable(false)
          .bindSheet(this.isShowDownload, this.DownloadSheet(), this.downloadSheetOptions)
          .onClick(() => { this.isShowDownload = true })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .visibility(this.downloadQueue.length > 0 ? Visibility.Visible : Visibility.None)

      Row() {
        Image(this.playmode === PLAYMODE.LOCAL ? this.picUrl : this.picUrl + '?param=512y512')
          .gesture(GestureGroup(GestureMode.Exclusive,
            TapGesture({ count: 2 })
              .onAction(() => {
                lyricsPipManager.handleClickPip()
              }),
          ))
          .height(Constants.HEIGHT_MINI)
          .aspectRatio(1)
          .borderRadius(Constants.RADIUS_IMG)
          .padding(5)

        Column({ space: 5 }) {
          Text(this.song.name).textStyle(16).fontWeight(FontWeight.Medium)
          Text((!this.currentLyric || this.currentLyric === '暂无歌词') ?
          this.artists : this.currentLyric)
            .textStyle(12)
            .textOverflow({ overflow: TextOverflow.MARQUEE })
            .layoutWeight(1)
            .fontColor(Color.Gray)
        }
        .onClick(this.handlePlayClick)
        .padding({ top: 10, bottom: 10 })
        .layoutWeight(1)

        this.ControlButton()
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .borderRadius(Constants.RADIUS_IMG)
      .height(Constants.HEIGHT_MINI)
      .width('100%')
      .backdropBlur(this.miniBarBlur ? 100 : 0)
      .backgroundColor(this.miniBarBlur ? Color.Transparent : $r('app.color.main'))
      .background(this.miniBarBlur ? this.Background() : null)
      .constraintSize({
        minWidth: 100,
        maxWidth: 500
      })
      .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.9 })
      .bindContentCover($$this.isShow, this.Player(), {
        modalTransition: ModalTransition.DEFAULT
      })
    }
  }

  @Builder Background() {
    Column()
      .height('100%')
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.main'))
      .opacity(this.miniBarBlur ? 0.5 : 1)
  }

  @Builder Player() {
    Player({ isShow: this.isShow })
      .height('100%')
  }

  @Builder ControlButton() {
    Row({ space: 10 }) {
      // Last
      Image($r('app.media.ic_public_play_last'))
        .buttonImgStyle()
        .fillColor($r('app.color.app_red'))
        .onClick(() => {
          ClickUtil.throttle(() => {
            playPre()
          }, 500)
        })

      // Play & Pause
      Stack() {
        Progress({
          value: this.playTime,
          total: this.song.duration,
          type: ProgressType.Ring
        })
          .width(30)
          .style({
            strokeWidth: 2
          })
          .color($r('app.color.app_red'))

        Image(this.isPaused ? $r('app.media.ic_play_fill') : $r('app.media.ic_public_pause'))
          .buttonImgStyle()
          .width(16)
          .padding({ left: this.isPaused ? 3 : 0})
          .fillColor($r('app.color.app_red'))
          .onClick(() => {
            if(!this.isPlaying) {
              setTimeout(() => {
                playQueue(playQueueUtils.currentQueueIndex)
              }, 100)
            } else {
              if(this.isPaused) resumeMusic()
              else pauseMusic()
            }
          })
      }

      // Next
      Image($r('app.media.ic_public_play_next'))
        .buttonImgStyle()
        .fillColor($r('app.color.app_red'))
        .onClick(() => {
          ClickUtil.throttle(() => {
            playNext()
          }, 500)
        })

      PlayQueueButton({ imgWidth: 25, imgColor: $r('app.color.app_red') })
    }
    .padding({ right: 5 })
  }

  @Builder DownloadSheet() {
    DownloadListSheet()
  }
}

@Extend(Image) function buttonImgStyle() {
  .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.6 })
  .aspectRatio(1)
  .width(30)
  .fillColor($r('app.color.reverse'))
  .draggable(false)
}

@Extend(Text) function textStyle(size:number) {
  .fontSize(size)
  .fontColor($r('app.color.reverse'))
  .textAlign(TextAlign.Start)
  .layoutWeight(1)
  .width('100%')
  .maxLines(1)
  .padding({ left: 10, right: 10 })
  .textOverflow({ overflow: TextOverflow.Ellipsis })
}