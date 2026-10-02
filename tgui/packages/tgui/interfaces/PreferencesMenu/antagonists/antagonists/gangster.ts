import { Antagonist, Category } from '../base';

const Gangster: Antagonist = {
  key: 'gangster',
  name: 'Gang Boss',
  description: [
    `
      A violent turf war has erupted on the station! Recruit crew members
      with your pen, tag territory with your spraycan to earn influence,
      buy weapons from your gangtool, and take over the station by
      defending a Dominator.
    `,
  ],
  category: Category.Roundstart,
};

export default Gangster;
