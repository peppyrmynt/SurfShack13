import { Antagonist, Category } from '../base';

const Flood: Antagonist = {
  key: 'flood',
  name: 'Flood',
  description: [
    `
      Begin as the Flood Overseer. Spread biomass across the station, direct
      the hive, and infect dead hosts to grow your forces.
    `,
  ],
  category: Category.Midround,
};

export default Flood;
