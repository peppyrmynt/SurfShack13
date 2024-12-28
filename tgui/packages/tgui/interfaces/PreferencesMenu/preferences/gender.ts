export enum Gender {
  Male = 'male',
  Female = 'female',
}

export const GENDERS = {
  [Gender.Male]: {
    icon: 'mars',
    text: 'He/Him',
  },

  [Gender.Female]: {
    icon: 'venus',
    text: 'She/Her',
  },
};
