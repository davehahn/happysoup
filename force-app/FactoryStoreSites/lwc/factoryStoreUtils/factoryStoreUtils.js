 /**
 * Created by Tim on 2021-04-05.
 */

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

const gen8DigitId = () => {
  return Math.random().toString(36).substring(2, 10);
}

const getDeals = (numToShow) => {
  numToShow = (numToShow === 'All') ? 6 : parseInt(numToShow);
  let dealsTemp = [];
  let dealId = 1;
  let dealsJSON = {
    "data": {
      "DealName": "Winterization",
			"StartDate": "04/10/2021",
			"EndDate": "08/18/2021",
			"Description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent porttitor blandit nibh at congue. Nullam sed tortor lacus. Aenean aliquet quam quis elit molestie, id commodo eros euismod. Nulla eget odio fermentum dolor lobortis suscipit. Nunc vulputate dui mi, et iaculis erat accumsan at. Morbi interdum vestibulum nulla quis sagittis. Pellentesque non nisl ut ante convallis mollis. Cras in tempus massa. Curabitur at feugiat leo.",
			"BannerGraphic": "https://mk0inventorylegv1t7j.kinstacdn.com/wp-content/uploads/2021/04/winterization-temp.jpg",
			"ButtonText": "Learn more about winterization",
			"ButtonURL": ""
    },
  };
  for(let i=0; i<numToShow; ++i){
    dealsTemp[i] = dealsJSON;
  }
	console.log('dealsTemp', dealsTemp);

  const deals = dealsTemp.map(o => ({
    ...o, DataId: gen8DigitId()
  }));

  return new Promise((resolve, reject) => {
    if(deals.length > 0){
      resolve(deals);
    } else {
      reject('Deals not found');
    }
  });
}

export {
	getDeals,
}