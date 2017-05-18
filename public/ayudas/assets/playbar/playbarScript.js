cp.playbarAssetArr = 
[
	'AudioOff',
	'AudioOn',
	'BackGround',
	'Backward',
	'Color',
	'ColorSmall',
	'CC',
	'Exit',
	'FastForward',
	'FastForward1',
	'FastForward2',
	'Forward',
	'Glow',
	'GlowSmall',
	'Height',
	'Play',
	'Pause',
	'Progress',
	'Rewind',
	'Stroke',
	'StrokeSmall',
	'Thumb',
	'ThumbBase',
	'TOC'
];
cp.playbarTooltips = 
{
	AudioOff : "Audio act.",
	AudioOn : "Audio desact. ",
	Backward : "Atrás ",
	CC : "Subtítulos opcionales ",
	Exit : "Salir ",
	FastForward : "Velocidad de avance rápido 2x ",
	FastForward1 : "Velocidad de avance rápido 4x ",
	FastForward2 : "Velocidad normal ", 
	Forward : "Adelante ",
	Play : "Reproducir ",
	Pause : "Pausa ",
	Rewind : "Rebobinar ",
	TOC : "Contenido ",
	Info : "Información ",
	Print : "Imprimir "
};
cp.responsiveButtons = 
{
	//"ButtonName"	: 	[Primary,Tablet,Mobile],
	"Rewind"		: 	[true,true,true,true,false],
	"Backward"		: 	[true,true,true,true,true],
	"Play"			: 	[true,true,true,true,true],
	"Slider"		: 	[true,true,true,true,false],
	"Forward"		: 	[true,true,true,true,true],
	"CC"			: 	[true,true,true,true,true],
	"AudioOn"		: 	[true,true,false,false,false],
	"Exit"			: 	[true,true,true,true,true],
	"FastForward"	: 	[true,true,true,true,false],
	"TOC"			: 	[true,true,true,true,false]
};
cp.handleSpecialForPlaybar = function(playbarConstruct)
{
}