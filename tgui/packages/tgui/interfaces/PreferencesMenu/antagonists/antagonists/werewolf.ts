import { Antagonist, Category } from '../base';

const Werewolf: Antagonist = {
  key: 'werewolf',
  name: 'Werewolf',
  description: [
    `
      You are a Werewolf. A member of a supernatural species believed to be mere myth amongst humanity.
	  Recently, your pack has been searching amongst the stars for hunt and recruit alike,
	  and after hearing about the isolation and danger aboard Space Station 13... it seemed like a
	  promising target for your pack's goals.
    `,

    `
      Infiltrate Space Station 13 as a bloodthristy werewolf to cause havoc amongst the crew!
    `,
  ],
  category: Category.Roundstart,
};

export default Werewolf;
