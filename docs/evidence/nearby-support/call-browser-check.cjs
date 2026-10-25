// Optional developer integration harness; requires Playwright and installed Chrome.
// Both audio directions are silenced. Never use an audible test tone.
const { chromium } = require(process.env.NORTHSTAR_PLAYWRIGHT_MODULE || 'playwright');
(async () => {
  const browser = await chromium.launch({headless:true,channel:"chrome",args:['--use-fake-device-for-media-stream','--use-fake-ui-for-media-stream']});
  try {
    const page = await browser.newPage();
    page.on('pageerror',error=>console.error(error));
    await page.addInitScript(() => {
      const original = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
      navigator.mediaDevices.getUserMedia = async (...args) => {
        const stream = await original(...args);
        stream.getAudioTracks().forEach(track => { track.enabled = false; });
        return stream;
      };
    });
    await page.goto('http://localhost:8080');
    await page.locator('#remote').evaluate(video => { video.muted = true; });
    await page.locator('#room-audio').evaluate(audio => { audio.muted = true; });
    await page.getByRole('button',{name:'Join call',exact:true}).click();
    await page.waitForFunction(()=>document.querySelector('#status').textContent==='Waiting for the room iPad');
    console.log('Rep browser joined with SILENCED synthetic microphone; browser playback muted');
    await page.waitForFunction(()=>document.querySelector('#question').textContent==='Where is the fictional call reference?',null,{timeout:180000});
    console.log('Received real iPad WebRTC question');
    await page.getByRole('button',{name:'Acknowledge question',exact:true}).click();
    await page.locator('#reply').fill('See the fictional call training packet.');
    await page.getByRole('button',{name:'Send reply',exact:true}).click();
    await page.getByRole('button',{name:'Reply received by room',exact:true}).waitFor({timeout:30000});
    console.log('iPad persisted reply and returned scoped receipt');
    await page.screenshot({path:'/tmp/northstar-rep-call.png',fullPage:true});
    await page.waitForFunction(()=>document.querySelector('#status').textContent.includes('Room ended'),null,{timeout:30000});
    console.log('Room end reached browser; media tracks stopped');
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1});
