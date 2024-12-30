export default function App({ children }) {
  const currentYear = new Date().getFullYear();
  return (
    <div>
      <section className="WallScreen">
        <div className="wallScreen wallScreenImg">
          <div className="doted">

            <div className="mainTitle appTitle">
              co.bike
            </div>

            <div className="text-center">
              <div className="col-xs-12 bottomScreen">
                <div className="LinkBlank">co.bike &copy; {currentYear}</div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
