'use strict';

window.ROLAND_LOOKS = Object.freeze([
  ['01','夜色红底','A SECRET IN RED','standing',10.50],
  ['02','奶油假日','A DAY TO LINGER','standing',11.41],
  ['03','绯红小恶魔','A LITTLE MISCHIEF','standing',11.20],
  ['04','蓝结心事','TIED WITH CARE','standing',10.50],
  ['05','黑衫偷闲','OFF THE CLOCK','standing',10.56],
  ['06','酒红赴约','WORTH DRESSING FOR','standing',11.70],
  ['07','雾灰银光','A QUIET GLEAM','standing',11.41],
  ['08','开衫午后','A SLOW AFTERNOON','standing',10.53],
  ['09','薄纱晚风','EVENING VEIL','standing',11.23],
  ['classic-20','暮蓝潮汐','BLUE HOUR','standing',11.30],
  ['classic-24','晴海微风','SEA BREEZE','standing',10.50],
  ['sit-01','夜幕丝绒','VELVET NIGHT','sitting',6.80],
  ['sit-02','黑衫轻语','A QUIET WORD','sitting',5.70],
  ['sit-04','白衫偷懒','SLOW MORNING','sitting',6.80],
  ['sit-05','墨格从容','INK AND PLAID','sitting',6.80],
  ['sit-06','绯色来信','A LETTER IN RED','sitting',6.80],
  ['sit-07','粉结初晴','PINK SKIES','sitting',6.80],
  ['sit-12','雾灰轻暖','SOFT GREY','sitting',6.80],
  ['sit-13','簪花小令','A FLOWER VERSE','sitting',6.80],
  ['sit-14','黑裙侧影','BLACK SILHOUETTE','sitting',6.80],
  ['sit-16','青灰浮光','PALE LIGHT','sitting',6.80],
  ['recline-01','紫暮长靴','VIOLET DUSK','reclining',11.70],
  ['recline-02','暖织冬日','WINTER KNIT','reclining',11.70],
  ['recline-03','晴蓝百褶','CLEAR BLUE','reclining',10.32],
  ['recline-04','墨色慵懒','INK AT REST','reclining',11.70],
  ['recline-05','奶霜花边','CREAM LACE','reclining',11.24],
  ['recline-06','灰格书卷','GREY CHAPTER','reclining',11.70],
  ['recline-07','豹纹不羁','UNTAMED','reclining',11.70]
].map(([id,name,english,group,freeze], index) => Object.freeze({
  id, name, english, group, freeze, index,
  image: `assets/images/look-${id}.jpg`,
  thumb: `assets/images/thumb-${id}.jpg`,
  opening: group === 'sitting' ? `assets/images/opening-${id}.jpg` : null,
  video: `assets/media/look-${id}.webm`,
  dialogue: [
    `${name}。今天想以这一身陪你。`,
    `这套被你选中了。慢慢看，不用着急。`,
    `衣服已经整理好，接下来把时间留给你。`
  ]
})));
