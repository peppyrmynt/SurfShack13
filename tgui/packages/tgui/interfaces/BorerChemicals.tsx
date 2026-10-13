import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type BorerChem = {
  id: string;
  name: string;
  desc: string;
  cost: number;
  units: number;
};

type Data = {
  chemicals: number;
  max_chemicals: number;
  docile: BooleanLike;
  host_name?: string;
  chems: BorerChem[];
};

export const BorerChemicals = (props) => {
  const { act, data } = useBackend<Data>();
  const { chemicals, max_chemicals, docile, host_name, chems = [] } = data;

  return (
    <Window width={440} height={600} title="Secrete Chemicals" theme="abductor">
      <Window.Content scrollable>
        <Section title="Reservoirs">
          <LabeledList>
            <LabeledList.Item label="Host">
              {host_name || 'None'}
            </LabeledList.Item>
            <LabeledList.Item label="Chemicals">
              <ProgressBar
                value={chemicals}
                maxValue={max_chemicals}
                ranges={{
                  good: [max_chemicals * 0.5, Infinity],
                  average: [max_chemicals * 0.2, max_chemicals * 0.5],
                  bad: [-Infinity, max_chemicals * 0.2],
                }}
              >
                {chemicals} / {max_chemicals}
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        {!!docile && (
          <NoticeBox danger>
            There is sugar in your host&apos;s blood. You are far too docile to
            secrete anything.
          </NoticeBox>
        )}
        <Section title="Secrete into the bloodstream">
          <Stack vertical>
            {chems.map((chem) => (
              <Stack.Item key={chem.id}>
                <Stack align="center">
                  <Stack.Item grow>
                    <Box bold>
                      {chem.name}{' '}
                      <Box inline color="label">
                        ({chem.units}u)
                      </Box>
                    </Box>
                    <Box color="label" fontSize="11px">
                      {chem.desc}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      width="70px"
                      textAlign="center"
                      icon="syringe"
                      disabled={!!docile || chemicals < chem.cost}
                      onClick={() => act('secrete', { id: chem.id })}
                    >
                      {chem.cost}
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
