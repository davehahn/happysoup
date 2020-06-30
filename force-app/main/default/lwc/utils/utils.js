/**
 * Created by dave on 2020-02-27.
 */
let konamiMsg = '';
let konamiCount = 0;

const gen8DigitId = () => {
  return Math.random().toString(36).substring(2, 10);
}

const konamiHandler = (event) => {
  // If the key isn't in the pattern, or isn't the current key in the pattern, reset
  const konamiPattern = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a'];

  console.log( event.key );
  if (konamiPattern.indexOf(event.key) < 0 || event.key !== konamiPattern[konamiCount])
  {
    console.log('miss');
    konamiCount = 0;
    return;
  }
  // Update how much of the pattern is complete
  console.log(konamiCount);
  konamiCount++;
  // If complete, alert and reset
  if (konamiPattern.length === konamiCount) {
    konamiCount = 0;
    console.log('pattern match');
    window.alert(konamiMsg);
  }
}

const konamiAdd = (msg) => {
  console.log('konami add');
  konamiMsg = msg;
  konamiCount = 0;
  document.addEventListener('keydown', konamiHandler );
}

const konamiRemove = () => {
  console.log('remove konami event')
  document.removeEventListener('keydown', konamiHandler );
}

export {
  gen8DigitId,
  konamiAdd,
  konamiRemove
}
