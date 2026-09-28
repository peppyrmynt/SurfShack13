import { useState } from 'react';
import { LabeledList, Section, Stack, Tabs } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  Objective,
  ObjectivePrintout,
  ReplaceObjectivesButton,
} from './common/Objectives';

type Form = 'Combat' | 'Carrier' | 'Constructor' | 'Overseer';
type GuideTab = 'Overview' | Form;
type GuideEntry = { label: string; text: string };
type Guide = { summary: string; entries: GuideEntry[] };

type Data = {
  current_form?: Form;
  objectives: Objective[];
  can_change_objective: BooleanLike;
};

const tabs: GuideTab[] = [
  'Overview',
  'Combat',
  'Carrier',
  'Constructor',
  'Overseer',
];

const guides: Record<Form, Guide> = {
  Combat: {
    summary: 'Fight for the infestation and evolve into a specialized form.',
    entries: [
      {
        label: 'Equipment',
        text: 'Normal combat forms spawn empty-handed. You can pick up and use ordinary station equipment and guns. AI combat forms may scavenge guns; no normal spawn starts with one.',
      },
      {
        label: 'Evolution',
        text: 'Use Evolve Flood Form to become a carrier or constructor. Constructors can become overseers when the hive has no living overseer and the death penalty has ended. Combat forms cannot produce infection forms directly.',
      },
      {
        label: 'Infected hosts',
        text: 'A human converted by an infection form becomes an empty-handed combat form with their original name. Their gear drops on the floor, and a player-controlled converted form has extra health.',
      },
      {
        label: 'Attacks',
        text: 'Your melee attacks damage targets but never infect them. Infection requires an infection form attached to a dead human.',
      },
    ],
  },
  Carrier: {
    summary: 'Bring a swarm into a fight and rupture to release it.',
    entries: [
      {
        label: 'Release',
        text: 'Use Release Infection Forms to burst immediately. Attacking in melee or dying also bursts the carrier. Bursting destroys your carrier body.',
      },
      {
        label: 'Swarm',
        text: 'A burst releases 6 to 12 AI infection forms onto nearby open tiles, along with a small Reactive Spines smoke cloud.',
      },
      {
        label: 'AI behavior',
        text: 'An uncontrolled carrier bursts when it gets within three tiles of a visible target it is pursuing, before making melee contact.',
      },
      {
        label: 'After bursting',
        text: 'Infection forms are AI-controlled and cannot be taken over through the ghost spawner menu. Protect them as they latch onto hosts.',
      },
    ],
  },
  Constructor: {
    summary: 'Build the infestation on the floor beneath you.',
    entries: [
      {
        label: 'Infest Floor',
        text: 'Cover the floor you stand on with Flood growth. It does not replace ordinary station walls or airlocks. Flood forms slowly heal while standing on this floor.',
      },
      {
        label: 'Grow Biomass',
        text: 'Create a small biomass spawner on your tile every 60 seconds. Spawners spread growth and produce Flood forms while limiting their nearby population.',
      },
      {
        label: 'Structures',
        text: 'Build a solid wall, a door, or a translucent membrane on your tile. Wall growth has a 15-second cooldown; successful construction also has a shared two-second recovery.',
      },
      {
        label: 'Produce Infection Form',
        text: 'Bud off one AI infection form every 45 seconds. Uncontrolled constructors also produce them over time.',
      },
      {
        label: 'Grow Spore Cluster',
        text: 'Place a cluster on your tile every 180 seconds. When a human passes through it, the cluster bursts after two seconds and releases four infection forms. Too many nearby clusters block placement.',
      },
      {
        label: 'Become Overseer',
        text: 'Only one living overseer can exist at a time. After one dies, the hive must recover for four minutes before any constructor can become the new overseer.',
      },
    ],
  },
  Overseer: {
    summary: 'Grow the nest and command nearby AI Flood forms.',
    entries: [
      {
        label: 'Create forms',
        text: 'Create a constructor every 30 seconds or a carrier every 120 seconds. Both appear on your tile as separate AI forms.',
      },
      {
        label: 'Direct Infestation Growth',
        text: 'Spread growth to up to three nearby floor tiles with a 30-second cooldown.',
      },
      {
        label: 'Overseer Mode',
        text: 'Stand on Flood-covered floor and toggle Overseer Mode. Your viewpoint can move across Flood biomass while your physical body remains in place and vulnerable. Other Flood players can see your marker.',
      },
      {
        label: 'Middle-click orders',
        text: 'In Overseer Mode, middle-click a living human within 15 tiles of your view to direct nearby AI Flood forms, including infection forms, to attack them. Middle-click a floor tile to rally those forms there. Player-controlled forms are unaffected.',
      },
      {
        label: 'Death',
        text: 'Your death shocks the hive for four minutes. Surviving Flood briefly stop, move more slowly, and lose Flood Chorus until a new overseer can emerge.',
      },
    ],
  },
};

export const AntagInfoFlood = () => {
  const { data } = useBackend<Data>();
  const { current_form, objectives = [], can_change_objective } = data;
  const [tab, setTab] = useState<GuideTab>(current_form || 'Overview');

  return (
    <Window width={720} height={620}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs fluid>
              {tabs.map((guideTab) => (
                <Tabs.Tab
                  key={guideTab}
                  selected={tab === guideTab}
                  onClick={() => setTab(guideTab)}
                >
                  {guideTab === current_form ? `${guideTab} (you)` : guideTab}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            <Section
              fill
              scrollable
              title={tab === 'Overview' ? 'The Flood' : `${tab} Form`}
            >
              {tab === 'Overview' ? (
                <Stack vertical>
                  <Stack.Item>
                    Expand the infestation, protect corpses for your infection
                    forms, and establish Flood biomass. You share Floodmind
                    speech nearby with :f, and Flood Chorus reaches every active
                    Flood player.
                  </Stack.Item>
                  <Stack.Item>
                    <Section title="Infection forms (AI allies)">
                      Infection forms cannot be taken over from the ghost spawner.
                      They leap onto a human and remain buckled to them. Against
                      living hosts, they deal 10 brute every two seconds; the
                      host can resist or the form can be killed to break the
                      latch. Only a dead human can be converted, after five
                      seconds attached to the corpse. Their swarms can merge,
                      and an unlatched form can reanimate a fallen Flood combat
                      form once. Dying infection forms also release a small
                      Reactive Spines smoke cloud.
                    </Section>
                  </Stack.Item>
                  <Stack.Item>
                    <Section title="Biomass and fire">
                      Flood forms heal slowly only while standing on
                      Flood-covered floor. Fire burns Flood bodies and can
                      destroy biomass; crew can also clear floor growth with a
                      welder or by removing the floor.
                    </Section>
                  </Stack.Item>
                  <Stack.Item>
                    <ObjectivePrintout
                      objectives={objectives}
                      objectiveFollowup={
                        <ReplaceObjectivesButton
                          can_change_objective={can_change_objective}
                          button_title="Change Objective"
                          button_colour="red"
                        />
                      }
                    />
                  </Stack.Item>
                </Stack>
              ) : (
                <Stack vertical>
                  <Stack.Item>{guides[tab].summary}</Stack.Item>
                  <Stack.Item>
                    <LabeledList>
                      {guides[tab].entries.map((entry) => (
                        <LabeledList.Item key={entry.label} label={entry.label}>
                          {entry.text}
                        </LabeledList.Item>
                      ))}
                    </LabeledList>
                  </Stack.Item>
                </Stack>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
