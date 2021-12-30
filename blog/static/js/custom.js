// https://stackoverflow.com/a/70385342/1040915
tweakBottomPadding();
tweakWidth();

function tweakBottomPadding() {
  // The Ananke theme hard-codes `pb7` Tachyon (http://tachyons.io/) class (https://bit.ly/3myqBFy),
  // leading to `padding-bottom: 16rem` which is (IMO) much too large.
  // I could instead have overridden the `_default/baseof` layout, but I prefer to make small
  // overrides rather than fork at a static version.
  var main = document.getElementsByTagName('main')[0];
  // https://stackoverflow.com/a/16337545/1040915
  // I wish all IE8 users a very Not Fucking Working Internet.
  if (main.classList.contains('pb7')) {
    main.classList.add('pb5');
    main.classList.remove('pb7');
    console.log('Reduced bottom-padding');
  } else {
    console.log('`main` element does not have pb7 class - not replacing it');
  }
}

function tweakWidth() {
  var article = document.getElementsByTagName('article')[0];
  if (article.classList.contains('mw8')) {
    article.classList.add('mw9');
    article.classList.remove('mw8');
    console.log('Widened article element');
  } else {
    console.log('`article` element does not have mw8 class - not replacing it');
  }
}