import { Antagonist, Category } from '../base';

const Swarmer: Antagonist = {
  key: 'swarmer',
  name: 'Swarmer',
  description: [
    `
      Consume walls, structures and anything else you can to get materials.
    `,
  ],
  category: Category.Midround,
};

export default Swarmer;
