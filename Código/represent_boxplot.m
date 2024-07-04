function represent_boxplot(Component_1,Component_2,nametitle)

x = [Component_1, Component_2];

g1 = repmat({'Before Stimulus'},1,length(Component_1));
g2 = repmat({'After Stimulus'},1,length(Component_2));

g = [g1,g2];

boxplot(x,g);
title(nametitle)